import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _codeRequested = false;
  bool _loading = false;
  String? _demoCode;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await AuthService.forgotPassword(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _demoCode = result['demoCode'] as String? ?? result['demo_code'] as String?;
        _message = _demoCode == null
            ? 'Si el correo existe, recibirás un código de recuperación.'
            : 'No hay correo configurado. Usa el código de prueba que aparece abajo.';
      });
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada. Ya puedes iniciar sesión.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¿Se te olvidó tu contraseña?',
                      style: DevTheme.display(size: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _codeRequested
                          ? 'Ingresa el código de 6 dígitos y crea una contraseña nueva.'
                          : 'Escribe el correo de tu cuenta y te enviaremos un código de recuperación.',
                      style: DevTheme.body(size: 14, color: DevColors.mutedFg),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_codeRequested,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration('Correo electrónico', Icons.email_outlined),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    if (_codeRequested) ...[
                      const SizedBox(height: 16),
                      if (_message != null)
                        Text(_message!, style: DevTheme.body(size: 13, color: DevColors.mutedFg)),
                      if (_demoCode != null) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          'Código de prueba: $_demoCode',
                          textAlign: TextAlign.center,
                          style: DevTheme.body(size: 15, color: DevColors.gold),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: _decoration('Código de 6 dígitos', Icons.verified_outlined),
                        validator: (value) => value == null || !RegExp(r'^\d{6}$').hasMatch(value.trim())
                            ? 'Ingresa el código de 6 dígitos'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _decoration('Nueva contraseña', Icons.lock_outline),
                        validator: (value) => value == null || value.length < 6
                            ? 'Usa al menos 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: _decoration('Repite la nueva contraseña', Icons.lock_outline),
                        validator: (value) => value != _passwordController.text
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : (_codeRequested ? _resetPassword : _requestCode),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_codeRequested ? 'Cambiar contraseña' : 'Enviar código'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: DevColors.cardRaised,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );
}
