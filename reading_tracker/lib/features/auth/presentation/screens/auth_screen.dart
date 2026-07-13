import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backend/supabase_client_provider.dart';
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
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegisterMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    ref.listen<AuthControllerState>(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated == true || !next.isAuthenticated) return;
      if (kDebugMode) {
        debugPrint(
          '[auth] authenticated on route=${ModalRoute.of(context)?.settings.name}; '
          'scheduling redirect to /',
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
    });

    final isAuthConfigured = ref.watch(isSupabaseEnabledProvider);
    final isBusy = state.isRestoring || state.isLoading;
    const authUnavailableMessage =
        'La autenticacion no esta disponible en este entorno.';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.10),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ReadPpSurface(
                    padding: EdgeInsets.zero,
                    borderRadius: 30,
                    opacity: 0.96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _AuthBrandHeader(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isRegisterMode
                                    ? 'CREAR CUENTA'
                                    : 'INICIAR SESION',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.66,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: isBusy || !isAuthConfigured
                                    ? null
                                    : ref
                                          .read(
                                            authControllerProvider.notifier,
                                          )
                                          .signInWithGoogle,
                                icon: const Icon(Icons.login_rounded, size: 20),
                                label: Text(
                                  _isRegisterMode
                                      ? 'Registrarse con Google'
                                      : 'Continuar con Google',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _emailController,
                                enabled: isAuthConfigured && !isBusy,
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
                                enabled: isAuthConfigured && !isBusy,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) =>
                                    isBusy || !isAuthConfigured
                                    ? null
                                    : _submitEmailPassword(),
                                decoration: const InputDecoration(
                                  labelText: 'Contrasena',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton.icon(
                                onPressed: isBusy || !isAuthConfigured
                                    ? null
                                    : _submitEmailPassword,
                                icon: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 19,
                                ),
                                label: Text(
                                  _isRegisterMode
                                      ? 'Crear una cuenta'
                                      : 'Entrar con correo',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _AuthModeDivider(isRegisterMode: _isRegisterMode),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: isBusy || !isAuthConfigured
                                    ? null
                                    : () => setState(
                                        () => _isRegisterMode =
                                            !_isRegisterMode,
                                      ),
                                child: Text(
                                  _isRegisterMode
                                      ? '¿Ya tienes una cuenta? Inicia sesion'
                                      : '¿Aun no tienes cuenta? Registrate',
                                ),
                              ),
                              if (state.isRestoring) ...[
                                const SizedBox(height: AppSpacing.sm),
                                const LinearProgressIndicator(),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Comprobando tu sesion…',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                              if (!isAuthConfigured ||
                                  state.errorMessage != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  state.errorMessage ?? authUnavailableMessage,
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
                              const SizedBox(height: AppSpacing.lg),
                              Text.rich(
                                TextSpan(
                                  text: 'Al continuar aceptas los ',
                                  children: [
                                    TextSpan(
                                      text: 'Terminos de uso',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const TextSpan(text: ' y la '),
                                    TextSpan(
                                      text: 'Politica de privacidad.',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 30),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.52),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(19),
              boxShadow: AppShadows.soft(theme.colorScheme.primary),
            ),
            child: const Icon(
              AppIcons.libreria,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Bienvenida a ReadPp',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tu compañero de lecturas inteligente.\n'
            'Lleva el registro, descubre y crece.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.58),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeDivider extends StatelessWidget {
  const _AuthModeDivider({required this.isRegisterMode});

  final bool isRegisterMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            isRegisterMode ? '¿Ya tienes cuenta?' : '¿Aun no tienes cuenta?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.58),
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }
}
