import 'package:hive_ce/hive.dart';

part 'business_settings.g.dart';

/// Business data that SHOULD travel with backups (unlike AppSettings, which
/// holds device-level things like activation status, admin credentials,
/// theme, and chart toggles - none of which should ever be touched by a
/// Restore operation).
@HiveType(typeId: 14)
class BusinessSettings extends HiveObject {
  @HiveField(0)
  double openingCementStock;

  @HiveField(1)
  bool openingStockSet;

  @HiveField(2)
  double lowStockThreshold; // default 50 bags

  BusinessSettings({
    this.openingCementStock = 0,
    this.openingStockSet = false,
    this.lowStockThreshold = 50,
  });
}
