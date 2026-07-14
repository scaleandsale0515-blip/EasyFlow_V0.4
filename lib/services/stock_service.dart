import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/production.dart';
import '../models/transport.dart';
import '../models/purchase.dart';
import '../models/business_settings.dart';
import 'hive_service.dart';

class StockService {
  static Box<ProductionEntry> get _production =>
      Hive.box<ProductionEntry>(HiveBoxes.production);
  static Box<TransportEntry> get _transport =>
      Hive.box<TransportEntry>(HiveBoxes.transport);
  static Box<PurchaseEntry> get _purchase =>
      Hive.box<PurchaseEntry>(HiveBoxes.purchase);
  static Box<BusinessSettings> get _businessBox =>
      Hive.box<BusinessSettings>(HiveBoxes.businessSettings);

  static BusinessSettings get _business => _businessBox.getAt(0)!;

  // ---------------- Item-wise product stock ----------------

  /// Current stock for a given subcategory =
  /// total produced - total dispatched (where reduceFromStock == true)
  static double subcategoryStock(String subcategoryId) {
    double produced = 0;
    for (final entry in _production.values) {
      for (final row in entry.items) {
        if (row.subcategoryId == subcategoryId) produced += row.quantity;
      }
    }
    double dispatched = 0;
    for (final entry in _transport.values) {
      for (final row in entry.items) {
        if (!row.isCement &&
            row.subcategoryId == subcategoryId &&
            row.reduceFromStock) {
          dispatched += row.quantity;
        }
      }
    }
    return produced - dispatched;
  }

  /// Total stock across all subcategories under one category.
  static double categoryStock(String categoryId, List<String> subcategoryIds) {
    return subcategoryIds.fold(0.0, (sum, id) => sum + subcategoryStock(id));
  }

  // ---------------- Cement stock (live running ledger) ----------------

  static double get openingCementStock => _business.openingCementStock;

  static double totalCementPurchased() {
    return _purchase.values.fold(0.0, (sum, p) => sum + p.quantity);
  }

  static double totalCementUsed() {
    return _production.values.fold(0.0, (sum, p) => sum + p.cementBagsUsed);
  }

  /// Also accounts for cement bags dispatched via Transport (if toggled to
  /// reduce stock), since a trip can carry cement bags out too. Reads the
  /// new dedicated `cementBagsDispatched` field on TransportEntry, plus
  /// falls back to summing any legacy isCement item rows from before that
  /// field existed, so historical data entered before this update still
  /// counts correctly.
  static double totalCementDispatched() {
    double dispatched = 0;
    for (final entry in _transport.values) {
      if (entry.cementReduceFromStock) {
        dispatched += entry.cementBagsDispatched;
      }
      for (final row in entry.items) {
        if (row.isCement && row.reduceFromStock) {
          dispatched += row.quantity;
        }
      }
    }
    return dispatched;
  }

  static double currentCementStock() {
    return openingCementStock +
        totalCementPurchased() -
        totalCementUsed() -
        totalCementDispatched();
  }

  static double todayCementUsage() {
    final today = DateTime.now();
    return _production.values
        .where((p) =>
            p.date.year == today.year &&
            p.date.month == today.month &&
            p.date.day == today.day)
        .fold(0.0, (sum, p) => sum + p.cementBagsUsed);
  }

  static bool isLowStock() {
    return currentCementStock() <= _business.lowStockThreshold;
  }

  static Future<void> setOpeningStock(double qty) async {
    final s = _business;
    s.openingCementStock = qty;
    s.openingStockSet = true;
    await s.save();
  }

  static bool get openingStockConfigured => _business.openingStockSet;

  static double get lowStockThreshold => _business.lowStockThreshold;

  static Future<void> setLowStockThreshold(double value) async {
    final s = _business;
    s.lowStockThreshold = value;
    await s.save();
  }
}
