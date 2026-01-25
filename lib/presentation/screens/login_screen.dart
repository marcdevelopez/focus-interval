import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../data/services/app_mode_service.dart';
import '../../data/services/local_import_service.dart';
import '../../data/repositories/local_task_repository.dart';
import '../../data/repositories/local_task_run_group_repository.dart';
import '../../data/repositories/firestore_task_repository.dart';
import '../../data/repositories/firestore_task_run_group_repository.dart';
import '../../widgets/mode_indicator.dart';

enum _LoginImportChoice { useAccount, importLocal, cancel }

enum _EmailVerificationAction { verified, resend, useLocal, signOut }

enum _ReclaimAction { sendReset, cancel }

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
      if (mounted) context.go('/tasks');
      return;
    }

    final retention = ref.read(taskRunRetentionServiceProvider);
    final importService = LocalImportService(
      localTasks: LocalTaskRepository(),
      localGroups: LocalTaskRunGroupRepository(retentionService: retention),
      remoteTasks: FirestoreTaskRepository(
        firestoreService: ref.read(firestoreServiceProvider),
        authService: auth,
      ),
      remoteGroups: FirestoreTaskRunGroupRepository(
        firestoreService: ref.read(firestoreServiceProvider),
        authService: auth,
        retentionService: retention,
      ),
    );

    final hasLocalData = await importService.hasLocalData();
    if (!mounted) return;

    if (!hasLocalData) {
      await modeController.setAccount();
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
        if (mounted) context.go('/tasks');
        break;
      case _LoginImportChoice.importLocal:
        try {
          final summary = await importService.importAll();
          await modeController.setAccount();
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthServiceProvider);
    final authSupported = auth is! StubAuthService;
    final isGoogleDisabled = !_isGoogleSignInSupported;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
        actions: const [ModeIndicatorChip(compact: true)],
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
