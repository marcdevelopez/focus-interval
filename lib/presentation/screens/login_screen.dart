import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/github_oauth_models.dart';
import '../../data/services/app_mode_service.dart';
import '../../data/services/local_import_service.dart';
import '../../data/repositories/local_task_repository.dart';
import '../../data/repositories/local_task_run_group_repository.dart';
import '../../data/repositories/local_pomodoro_preset_repository.dart';
import '../../data/repositories/firestore_task_repository.dart';
import '../../data/repositories/firestore_task_run_group_repository.dart';
import '../../data/repositories/firestore_pomodoro_preset_repository.dart';
import '../../widgets/mode_indicator.dart';

enum _LoginImportChoice { useAccount, importLocal, cancel }

enum _EmailVerificationAction { verified, resend, useLocal, signOut }

enum _ReclaimAction { sendReset, cancel }

enum _LinkProviderChoice { google, email, cancel }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;

  void _invalidateAccountProviders() {
    ref.invalidate(taskListProvider);
    ref.invalidate(presetListProvider);
    ref.invalidate(presetEditorProvider);
  }

  bool get _isGoogleSignInSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _handlePostLogin({bool sendVerificationEmail = false}) async {
    final canProceed = await _ensureEmailVerified(
      sendEmail: sendVerificationEmail,
    );
    if (!canProceed) return;

    final auth = ref.read(firebaseAuthServiceProvider);
    final appMode = ref.read(appModeProvider);
    final modeController = ref.read(appModeProvider.notifier);
    final user = auth.currentUser;
    if (user == null) return;

    if (appMode == AppMode.account) {
      _invalidateAccountProviders();
      if (mounted) context.go('/tasks');
      return;
    }

    final retention = ref.read(taskRunRetentionServiceProvider);
    final importService = LocalImportService(
      localTasks: LocalTaskRepository(),
      localGroups: LocalTaskRunGroupRepository(retentionService: retention),
      localPresets: LocalPomodoroPresetRepository(),
      remoteTasks: FirestoreTaskRepository(
        firestoreService: ref.read(firestoreServiceProvider),
        authService: auth,
      ),
      remoteGroups: FirestoreTaskRunGroupRepository(
        firestoreService: ref.read(firestoreServiceProvider),
        authService: auth,
        retentionService: retention,
      ),
      remotePresets: FirestorePomodoroPresetRepository(
        firestoreService: ref.read(firestoreServiceProvider),
        authService: auth,
      ),
    );

    final hasLocalData = await importService.hasLocalData();
    if (!mounted) return;

    if (!hasLocalData) {
      await modeController.setAccount();
      _invalidateAccountProviders();
      if (mounted) context.go('/tasks');
      return;
    }

    final choice = await showDialog<_LoginImportChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Use this account?'),
          content: Text(
            'Signed in as ${user.email ?? user.uid}. Local Mode data stays on this device unless you import it. Importing will overwrite cloud items with the same IDs.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_LoginImportChoice.useAccount),
              child: const Text('Use account (no import)'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_LoginImportChoice.importLocal),
              child: const Text('Import local data'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_LoginImportChoice.cancel),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (!mounted || choice == null) return;

    switch (choice) {
      case _LoginImportChoice.useAccount:
        await modeController.setAccount();
        _invalidateAccountProviders();
        if (mounted) context.go('/tasks');
        break;
      case _LoginImportChoice.importLocal:
        try {
          final summary = await importService.importAll();
          await modeController.setAccount();
          _invalidateAccountProviders();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${summary.tasksImported} tasks and ${summary.groupsImported} groups to this account.',
              ),
            ),
          );
          context.go('/tasks');
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
        }
        break;
      case _LoginImportChoice.cancel:
        await auth.signOut();
        if (mounted) context.go('/tasks');
        break;
    }
  }

  Future<bool> _ensureEmailVerified({required bool sendEmail}) async {
    final auth = ref.read(firebaseAuthServiceProvider);
    if (!auth.requiresEmailVerification) return true;

    if (sendEmail) {
      await _sendVerificationEmail();
      if (!mounted) return false;
    }

    while (auth.requiresEmailVerification) {
      if (!mounted) return false;
      final action = await showDialog<_EmailVerificationAction>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Verify your email to enable sync'),
          content: Text(
              'We need to verify ${auth.currentUser?.email ?? 'this email'} before enabling Account Mode. '
              'Until then, sync is disabled. Check your spam folder if it does not arrive within a few minutes.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_EmailVerificationAction.useLocal),
                child: const Text('Use Local Mode'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_EmailVerificationAction.signOut),
                child: const Text('Sign out'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_EmailVerificationAction.resend),
                child: const Text('Resend email'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(_EmailVerificationAction.verified),
                child: const Text("I've verified"),
              ),
            ],
          );
        },
      );

      if (!mounted || action == null) return false;

      switch (action) {
        case _EmailVerificationAction.resend:
          await _sendVerificationEmail();
          break;
        case _EmailVerificationAction.verified:
          await auth.reloadCurrentUser();
          ref.invalidate(authStateProvider);
          if (!auth.requiresEmailVerification) {
            return true;
          }
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email still unverified. Please try again.'),
            ),
          );
          break;
        case _EmailVerificationAction.useLocal:
          await ref.read(appModeProvider.notifier).setLocal();
          if (!mounted) return false;
          context.go('/tasks');
          return false;
        case _EmailVerificationAction.signOut:
          await auth.signOut();
          return false;
      }
    }
    return true;
  }

  Future<void> _sendVerificationEmail() async {
    final auth = ref.read(firebaseAuthServiceProvider);
    try {
      await auth.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification email sent to ${auth.currentUser?.email ?? 'your email'}. '
            'Check your spam folder if it does not arrive soon.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: $e')),
      );
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final auth = ref.read(firebaseAuthServiceProvider);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter your email first.')));
      return;
    }
    try {
      await auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInEmail() async {
    setState(() => _loading = true);
    final auth = ref.read(firebaseAuthServiceProvider);
    try {
      await auth.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await _handlePostLogin();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No account found. Create one to continue.'),
          ),
        );
      } else if (e.code == 'wrong-password') {
        final action = await showDialog<_ReclaimAction>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Incorrect password'),
              content: const Text(
                'You can reset your password to reclaim this account.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ReclaimAction.cancel),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ReclaimAction.sendReset),
                  child: const Text('Send reset email'),
                ),
              ],
            );
          },
        );
        if (action == _ReclaimAction.sendReset) {
          await _sendPasswordResetEmail();
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-in error: $e')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpEmail() async {
    setState(() => _loading = true);
    final auth = ref.read(firebaseAuthServiceProvider);
    try {
      await auth.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await _handlePostLogin(sendVerificationEmail: true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        try {
          await auth.signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
          await _handlePostLogin();
        } on FirebaseAuthException {
          if (!mounted) return;
          final action = await showDialog<_ReclaimAction>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Account already exists'),
                content: const Text(
                  'This email is already registered. Sign in to verify the address, '
                  'or reset the password to reclaim the account.',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_ReclaimAction.cancel),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_ReclaimAction.sendReset),
                    child: const Text('Send reset email'),
                  ),
                ],
              );
            },
          );
          if (!mounted) return;
          if (action == _ReclaimAction.sendReset) {
            await _sendPasswordResetEmail();
          }
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-up error: $e')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-up error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    final auth = ref.read(firebaseAuthServiceProvider);
    try {
      await auth.signInWithGoogle();
      await _handlePostLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGitHub() async {
    setState(() => _loading = true);
    final auth = ref.read(firebaseAuthServiceProvider);
    try {
      if (auth.isGitHubDesktopOAuthSupported) {
        await _signInGitHubDesktop();
      } else {
        await auth.signInWithGitHub();
      }
      await _handlePostLogin();
    } on FirebaseAuthException catch (e) {
      final handled = await _tryResolveProviderConflict(e);
      if (handled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('GitHub sign-in error: $e')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('GitHub sign-in error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGitHubDesktop() async {
    final auth = ref.read(firebaseAuthServiceProvider);
    final flow = await auth.startGitHubDeviceFlow();
    if (!mounted) return;
    final proceed = await _showDeviceCodeDialog(flow);
    if (proceed != true) return;
    await auth.completeGitHubDeviceFlow(flow);
  }

  Future<bool> _tryResolveProviderConflict(
    FirebaseAuthException exception,
  ) async {
    if (exception.code != 'account-exists-with-different-credential') {
      return false;
    }
    final email = exception.email;
    final pending = exception.credential;
    if (email == null) {
      final action = await _chooseLinkProvider();
      if (action == _LinkProviderChoice.google) {
        return _linkViaGoogle(pending);
      }
      if (action == _LinkProviderChoice.email) {
        return _linkViaEmail(emailOverride: null, pending: pending);
      }
      return true;
    }

    final action = await _chooseLinkProvider();
    if (action == _LinkProviderChoice.google) {
      return _linkViaGoogle(pending);
    }
    if (action == _LinkProviderChoice.email) {
      return _linkViaEmail(emailOverride: email, pending: pending);
    }
    return true;
  }

  Future<bool> _linkViaGoogle(AuthCredential? pending) async {
    if (!_isGoogleSignInSupported) {
      if (!mounted) return true;
      await _showInfoDialog(
        title: 'Google account already exists',
        message:
            'This email is already registered with Google, and Google sign-in is not available on desktop.\n\n'
            'To link GitHub:\n'
            '1) Open the web or mobile app.\n'
            '2) Sign in with Google.\n'
            '3) Tap "Continue with GitHub" to link.\n'
            '4) Return here and sign in with GitHub again.',
      );
      return true;
    }
    final confirm = await _confirmLinkDialog(
      title: 'Account already exists',
      message:
          'This email is already registered with Google. Sign in with Google to link GitHub.',
      confirmLabel: 'Continue with Google',
    );
    if (confirm != true) return true;
    final auth = ref.read(firebaseAuthServiceProvider);
    setState(() => _loading = true);
    try {
      await auth.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: ${e.message ?? e.code}')),
      );
      return true;
    }
    try {
      if (pending != null) {
        await auth.linkWithCredential(pending);
      } else if (auth.isGitHubDesktopOAuthSupported) {
        await _linkGitHubDesktopFlow(auth);
      } else {
        await auth.linkWithGitHubProvider();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linking failed: ${e.message ?? e.code}')),
      );
      return true;
    }
    await _handlePostLogin();
    return true;
  }

  Future<bool> _linkViaEmail({
    required String? emailOverride,
    required AuthCredential? pending,
  }) async {
    final email = emailOverride ?? await _promptEmail();
    if (email == null) return true;
    final password = await _promptPassword(email);
    if (password == null) return true;
    final auth = ref.read(firebaseAuthServiceProvider);
    setState(() => _loading = true);
    try {
      await auth.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sign-in error: ${e.message ?? e.code}')),
      );
      return true;
    }
    try {
      if (pending != null) {
        await auth.linkWithCredential(pending);
      } else if (auth.isGitHubDesktopOAuthSupported) {
        await _linkGitHubDesktopFlow(auth);
      } else {
        await auth.linkWithGitHubProvider();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linking failed: ${e.message ?? e.code}')),
      );
      return true;
    }
    await _handlePostLogin();
    return true;
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkGitHubDesktopFlow(AuthService auth) async {
    final flow = await auth.startGitHubDeviceFlow();
    if (!mounted) return;
    final proceed = await _showDeviceCodeDialog(flow);
    if (proceed != true) return;
    await auth.linkWithGitHubDeviceFlow(flow);
  }

  Future<bool?> _showDeviceCodeDialog(GitHubDeviceFlowData flow) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Link GitHub'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter this code in your browser:'),
            const SizedBox(height: 8),
            SelectableText(
              flow.userCode,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Verification URL: ${flow.verificationUri}'),
            const SizedBox(height: 8),
            const Text(
              'Complete authorization in the browser, then continue here.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptEmail() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sign in to link GitHub'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return null;
    if (result != null && result.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email is required.')));
      return null;
    }
    return result?.trim();
  }

  Future<_LinkProviderChoice> _chooseLinkProvider() async {
    final result = await showDialog<_LinkProviderChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account already exists'),
        content: const Text(
          'This email is already registered with another provider. Choose how to sign in to link GitHub.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_LinkProviderChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_LinkProviderChoice.email),
            child: const Text('Email'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_LinkProviderChoice.google),
            child: const Text('Google'),
          ),
        ],
      ),
    );
    return result ?? _LinkProviderChoice.cancel;
  }

  Future<bool?> _confirmLinkDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptPassword(String email) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sign in to link GitHub'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(email),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return null;
    if (result != null && result.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password is required.')));
      return null;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthServiceProvider);
    final appMode = ref.watch(appModeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final authSupported = auth is! StubAuthService;
    final isGoogleDisabled = !_isGoogleSignInSupported;
    final isGitHubSupported =
        auth.isGitHubSignInSupported || auth.isGitHubDesktopOAuthSupported;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final allowLocalExit = appMode == AppMode.local && currentUser == null;

    if (!authSupported) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Authentication'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/tasks'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Authentication is not available on this platform.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/tasks'),
                  child: const Text('Back to tasks'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Authentication'),
        actions: [
          ModeIndicatorAction(
            compact: true,
            onTap: allowLocalExit ? () => context.go('/tasks') : null,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  suffixIcon: IconButton(
                    tooltip:
                        _passwordVisible ? 'Hide password' : 'Show password',
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _signInEmail,
                child: const Text('Sign in (email)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading ? null : _signUpEmail,
                child: const Text('Create account (email)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading || isGoogleDisabled ? null : _signInGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              if (isGitHubSupported) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signInGitHub,
                  icon: const Icon(Icons.code),
                  label: const Text('Continue with GitHub'),
                ),
              ],
              if (isGoogleDisabled)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Google Sign-In is not available on this platform; use email/password.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              if (_loading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
