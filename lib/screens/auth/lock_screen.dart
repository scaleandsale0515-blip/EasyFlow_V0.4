import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../home_shell.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  Future<void> _tryLogin() async {
    final ok = AuthService.verify(_idCtrl.text.trim(), _passCtrl.text);
    if (ok) {
      await AuthService.markActivated();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      setState(() => _error = 'Invalid ID or Password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryBlue.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('EasyFlow',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Admin login required',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Admin ID',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: TextStyle(color: AppColors.balanceRed)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _tryLogin,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Unlock', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
