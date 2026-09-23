import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';

class SmsVerificationDialog extends StatefulWidget {
  final String verificationId;
  final VoidCallback onVerified;

  const SmsVerificationDialog({
    super.key,
    required this.verificationId,
    required this.onVerified,
  });

  @override
  State<SmsVerificationDialog> createState() => _SmsVerificationDialogState();
}

class _SmsVerificationDialogState extends State<SmsVerificationDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_formKey.currentState!.validate()) {
      final authController = context.read<AuthController>();
      final success = await authController.verifyOtp(
        widget.verificationId,
        _codeController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        widget.onVerified();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthController>().state.status;
    final errorMessage = context.watch<AuthController>().state.errorMessage;

    return AlertDialog(
      title: const Text('Verificação de SMS'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insira o código de 6 dígitos enviado para o seu celular.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código SMS',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              validator: (value) =>
                  value != null && value.length == 6 ? null : 'Insira 6 dígitos',
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: authStatus == AuthStatus.loading ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: authStatus == AuthStatus.loading ? null : _verify,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: authStatus == AuthStatus.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('VERIFICAR', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
