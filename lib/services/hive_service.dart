import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/company_profile.dart';
import '../models/item_catalog.dart';
import '../models/worker.dart';
import '../models/transporter.dart';
import '../models/production.dart';
import '../models/transport.dart';
import '../models/purchase.dart';
import '../models/app_settings.dart';
import '../models/business_settings.dart';

class HiveBoxes {
  static const companyProfile = 'company_profile';
  static const categories = 'item_categories';
  static const subcategories = 'item_subcategories';
  static const customUnits = 'custom_units';
  static const workers = 'workers';
  static const workerPayments = 'worker_payments';
  static const transporters = 'transporters';
  static const transporterPayments = 'transporter_payments';
  static const production = 'production_entries';
  static const transport = 'transport_entries';
  static const purchase = 'purchase_entries';
  static const appSettings = 'app_settings'; // device-level - NEVER included in backups
  static const businessSettings = 'business_settings'; // portable - included in backups
}

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();

    // Open all boxes
    await Hive.openBox<CompanyProfile>(HiveBoxes.companyProfile);
    await Hive.openBox<ItemCategory>(HiveBoxes.categories);
    await Hive.openBox<ItemSubcategory>(HiveBoxes.subcategories);
    await Hive.openBox<CustomUnit>(HiveBoxes.customUnits);
    await Hive.openBox<Worker>(HiveBoxes.workers);
    await Hive.openBox<WorkerPayment>(HiveBoxes.workerPayments);
    await Hive.openBox<Transporter>(HiveBoxes.transporters);
    await Hive.openBox<TransporterPayment>(HiveBoxes.transporterPayments);
    await Hive.openBox<ProductionEntry>(HiveBoxes.production);
    await Hive.openBox<TransportEntry>(HiveBoxes.transport);
    await Hive.openBox<PurchaseEntry>(HiveBoxes.purchase);
    await Hive.openBox<AppSettings>(HiveBoxes.appSettings);
    await Hive.openBox<BusinessSettings>(HiveBoxes.businessSettings);

    await _migrateBusinessSettingsIfNeeded();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CompanyProfileAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ItemCategoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ItemSubcategoryAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CustomUnitAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(WorkerAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(WorkerPaymentAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(TransporterAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TransporterPaymentAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(ProductionItemRowAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(ProductionEntryAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransportItemRowAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(TransportEntryAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(PurchaseEntryAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(BusinessSettingsAdapter());
  }

  /// One-time migration: if this device already had opening stock / low
  /// stock threshold configured under the old combined AppSettings (from
  /// before BusinessSettings existed), carry those values over so nothing
  /// is silently reset to defaults after this update installs.
  static Future<void> _migrateBusinessSettingsIfNeeded() async {
    final businessBox = Hive.box<BusinessSettings>(HiveBoxes.businessSettings);
    if (businessBox.isNotEmpty) return; // already migrated or fresh install with real data

    final appBox = Hive.box<AppSettings>(HiveBoxes.appSettings);
    if (appBox.isNotEmpty) {
      final old = appBox.getAt(0)!;
      await businessBox.add(BusinessSettings(
        openingCementStock: old.openingCementStock,
        openingStockSet: old.openingStockSet,
        lowStockThreshold: old.lowStockThreshold,
      ));
    } else {
      await businessBox.add(BusinessSettings());
    }
  }

  /// Closes all open boxes - used before overwriting box files during Restore.
  static Future<void> closeAll() async {
    await Hive.close();
  }
}
