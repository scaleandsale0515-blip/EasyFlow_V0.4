import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'utils/app_theme.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await AuthService.ensureInitialized();
  ThemeService.loadInitial();
  runApp(const EasyFlowApp());
}

class EasyFlowApp extends StatelessWidget {
  const EasyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'EasyFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeService.instance.themeMode,
          // One-time activation: once this device has successfully unlocked
          // with the correct admin credentials, it skips straight to the
          // Dashboard on every future launch. Uninstalling wipes the local
          // Hive database, so a reinstall asks again - this is what makes
          // it work as a per-device activation/sale mechanism.
          home: AuthService.isActivated ? HomeShell() : const LockScreen(),
        );
      },
    );
  }
}
