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

enum _LoginImportChoice { useAccount, importLocal, cancel }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  bool get _isGoogleSignInSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _handlePostLogin() async {
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
      await _handlePostLogin();
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
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
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
