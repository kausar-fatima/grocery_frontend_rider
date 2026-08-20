import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _codeSent = false;
  bool _sending = false;
  bool _resetting = false;
  String? _demoCode;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthCubit>();
    setState(() => _sending = true);
    final result = await auth.forgotPassword(_email.text.trim());
    if (!mounted) return;
    setState(() => _sending = false);
    if (result == null) {
      _snack(auth.state.error ?? 'Could not send the reset code.');
      return;
    }
    setState(() {
      _codeSent = true;
      _demoCode = result.code;
      if (result.code != null) _code.text = result.code!;
    });
  }

  Future<void> _reset() async {
    if (!_resetKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthCubit>();
    setState(() => _resetting = true);
    final message = await auth.resetPassword(
      email: _email.text.trim(),
      code: _code.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _resetting = false);
    if (message == null) {
      _snack(auth.state.error ?? 'Could not reset your password.');
      return;
    }
    _snack(message);
    context.pop();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.55),
                    AppColors.surfaceMuted,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _blob(220, AppColors.primary.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _blob(260, AppColors.primary.withValues(alpha: 0.08)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _codeSent ? _buildResetForm() : _buildEmailForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _header(String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            'Forgot password?',
            'Enter your email and we\'ll send you a 6-digit code to reset your password.',
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send reset code',
            isLoading: _sending,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            'Reset password',
            'We sent a 6-digit code to ${_email.text.trim()}. Enter it below with your new password.',
          ),
          const SizedBox(height: 20),
          if (_demoCode != null) ...[
            _DemoCodeBanner(code: _demoCode!),
            const SizedBox(height: 16),
          ],
          AppTextField(
            label: 'Reset code',
            hint: '6-digit code',
            controller: _code,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_outlined,
            validator: (v) => (v == null || v.trim().length != 6)
                ? 'Enter the 6-digit code'
                : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'New password',
            hint: 'At least 6 characters',
            controller: _password,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) =>
                (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirm password',
            hint: 'Re-enter your new password',
            controller: _confirm,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                (v != _password.text) ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Reset password',
            isLoading: _resetting,
            onPressed: _reset,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _sending ? null : _sendCode,
              child: const Text('Resend code'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCodeBanner extends StatelessWidget {
  final String code;
  const _DemoCodeBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                children: [
                  const TextSpan(text: 'Demo mode — your reset code is '),
                  TextSpan(
                    text: code,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const TextSpan(text: '. It expires in 15 minutes.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
