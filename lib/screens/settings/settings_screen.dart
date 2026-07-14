import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/app_settings.dart';
import '../../services/hive_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_theme.dart';
import '../terms/terms_conditions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings get _settings => Hive.box<AppSettings>(HiveBoxes.appSettings).getAt(0)!;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _toggleChart(String field, bool value, String label) async {
    final s = _settings;
    switch (field) {
      case 'production':
        s.showProductionChart = value;
        break;
      case 'worker':
        s.showWorkerChart = value;
        break;
      case 'trends':
        s.showTrendsChart = value;
        break;
      case 'purchase':
        s.showPurchaseUsageChart = value;
        break;
    }
    await s.save();
    setState(() {});
    _toast(value ? '$label added to Dashboard' : '$label hidden from Dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: Hive.box<AppSettings>(HiveBoxes.appSettings).listenable(),
        builder: (context, _) {
          final s = _settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SettingsSectionLabel('Appearance'),
              Card(
                child: SwitchListTile(
                  secondary: Icon(ThemeService.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: AppColors.accentCyan),
                  title: const Text('Dark Mode'),
                  subtitle: Text(ThemeService.isDark ? 'Currently using Dark theme' : 'Currently using Light theme', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  value: ThemeService.isDark,
                  onChanged: (v) async {
                    await ThemeService.instance.setDark(v);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 24),
              const _SettingsSectionLabel('Dashboard Charts'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.bar_chart, color: AppColors.accentCyan),
                      title: const Text('Production Chart'),
                      value: s.showProductionChart,
                      onChanged: (v) => _toggleChart('production', v, 'Production Chart'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.person_outline, color: AppColors.accentCyan),
                      title: const Text('Worker Chart'),
                      value: s.showWorkerChart,
                      onChanged: (v) => _toggleChart('worker', v, 'Worker Chart'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.emoji_events_outlined, color: AppColors.accentCyan),
                      title: const Text('Trends Chart'),
                      value: s.showTrendsChart,
                      onChanged: (v) => _toggleChart('trends', v, 'Trends Chart'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.inventory_2_outlined, color: AppColors.accentCyan),
                      title: const Text('Purchase/Usage Chart'),
                      value: s.showPurchaseUsageChart,
                      onChanged: (v) => _toggleChart('purchase', v, 'Purchase/Usage Chart'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SettingsSectionLabel('About'),
              Card(
                child: ListTile(
                  leading: Icon(Icons.description_outlined, color: AppColors.accentCyan),
                  title: const Text('Terms & Conditions'),
                  trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen())),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String text;
  const _SettingsSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}
