import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form           = GlobalKey<FormState>();
  final _companyCtrl    = TextEditingController();
  final _nifCtrl        = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _postalCtrl     = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _companyEmail   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _pass2Ctrl      = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  bool _obscure2 = true;
  String? _error;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (_passCtrl.text != _pass2Ctrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.register(
        companyName:  _companyCtrl.text.trim(),
        email:        _emailCtrl.text.trim(),
        password:     _passCtrl.text,
        nif:          _nifCtrl.text.trim(),
        address:      _addressCtrl.text.trim(),
        city:         _cityCtrl.text.trim(),
        postalCode:   _postalCtrl.text.trim(),
        phone:        _phoneCtrl.text.trim(),
        companyEmail: _companyEmail.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_companyCtrl, _nifCtrl, _addressCtrl, _cityCtrl, _postalCtrl,
                     _phoneCtrl, _companyEmail, _emailCtrl, _passCtrl, _pass2Ctrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String label, TextEditingController ctrl, {
    TextInputType? type, bool required = false, bool obscure = false,
    Widget? suffix, VoidCallback? toggleObscure,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          suffixIcon: toggleObscure != null
            ? IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: toggleObscure)
            : null,
        ),
        validator: required ? (v) => v!.trim().isEmpty ? 'Campo obligatorio' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  elevation: 24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(14)),
                                  child: const Center(child: Text('🌻', style: TextStyle(fontSize: 28))),
                                ),
                                const SizedBox(height: 10),
                                const Text('SUNFLOWER ERP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                                const SizedBox(height: 4),
                                const Text('Crea tu empresa y comienza gratis', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                border: Border.all(color: const Color(0xFFFECACA)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                            ),
                            const SizedBox(height: 16),
                          ],

                          _sectionTitle('Datos de la empresa'),
                          _field('Nombre de la empresa', _companyCtrl, required: true),
                          Row(children: [
                            Expanded(child: _field('NIF / CIF', _nifCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: _field('Teléfono', _phoneCtrl, type: TextInputType.phone)),
                          ]),
                          _field('Dirección', _addressCtrl),
                          Row(children: [
                            Expanded(child: _field('Ciudad', _cityCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: _field('Código postal', _postalCtrl)),
                          ]),
                          _field('Email de la empresa', _companyEmail, type: TextInputType.emailAddress),

                          _sectionTitle('Tu cuenta de acceso'),
                          _field('Email de acceso', _emailCtrl, type: TextInputType.emailAddress, required: true),
                          Row(children: [
                            Expanded(child: _field('Contraseña', _passCtrl, required: true, obscure: _obscure,
                              toggleObscure: () => setState(() => _obscure = !_obscure))),
                            const SizedBox(width: 12),
                            Expanded(child: _field('Repetir contraseña', _pass2Ctrl, required: true, obscure: _obscure2,
                              toggleObscure: () => setState(() => _obscure2 = !_obscure2))),
                          ]),

                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Crear empresa y acceder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('¿Ya tienes cuenta? ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Inicia sesión', style: TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5), letterSpacing: 0.8)),
        const Divider(color: Color(0xFFEEF2FF), thickness: 2),
      ],
    ),
  );
}
