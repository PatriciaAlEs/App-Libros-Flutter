import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialRegisterMode = false});

  final bool initialRegisterMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegisterMode;
  }

  Future<void> _submitEmailPassword() async {
    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text;
    final password = _passwordController.text;

    if (_isRegisterMode) {
      await controller.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      return;
    }

    await controller.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  void _continueWithoutLogin() {
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: _continueWithoutLogin,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ReadPpSurface(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                borderRadius: 30,
                opacity: 0.94,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      AppIcons.profile,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Tu cuenta ReadPp',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Inicia sesion para sincronizar tu biblioteca y progreso en varios dispositivos.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Continuar con Google'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) =>
                          state.isLoading ? null : _submitEmailPassword(),
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: state.isLoading ? null : _submitEmailPassword,
                      child: Text(
                        _isRegisterMode ? 'Crear cuenta' : 'Iniciar sesion',
                      ),
                    ),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => setState(
                              () => _isRegisterMode = !_isRegisterMode,
                            ),
                      child: Text(
                        _isRegisterMode
                            ? 'Ya tengo cuenta'
                            : 'Crear cuenta con email',
                      ),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (state.isAuthenticated) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Sesion iniciada.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: state.isLoading ? null : _continueWithoutLogin,
                child: const Text('Continuar sin login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
