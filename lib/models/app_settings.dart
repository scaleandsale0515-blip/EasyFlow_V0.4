import 'package:hive_ce/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 13)
class AppSettings extends HiveObject {
  // --- Admin lock (SHA-256 salted, same pattern as EasyQuote) ---
  @HiveField(0)
  String adminIdHash;

  @HiveField(1)
  String adminPasswordHash;

  @HiveField(2)
  String salt;

  // --- Cement stock ---
  @HiveField(3)
  double openingCementStock;

  @HiveField(4)
  bool openingStockSet;

  @HiveField(5)
  double lowStockThreshold; // default 50 bags

  // --- Backup tracking ---
  @HiveField(6)
  DateTime? lastBackupDate;

  // --- One-time admin activation (device-level, resets on uninstall) ---
  @HiveField(7)
  bool isActivated;

  // --- Theme preference ---
  @HiveField(8)
  bool isDarkMode;

  // --- Dashboard chart visibility toggles ---
  @HiveField(9)
  bool showProductionChart;

  @HiveField(10)
  bool showWorkerChart;

  @HiveField(11)
  bool showTrendsChart;

  @HiveField(12)
  bool showPurchaseUsageChart;

  AppSettings({
    required this.adminIdHash,
    required this.adminPasswordHash,
    required this.salt,
    this.openingCementStock = 0,
    this.openingStockSet = false,
    this.lowStockThreshold = 50,
    this.lastBackupDate,
    this.isActivated = false,
    this.isDarkMode = true,
    this.showProductionChart = true,
    this.showWorkerChart = true,
    this.showTrendsChart = true,
    this.showPurchaseUsageChart = true,
  });
}
