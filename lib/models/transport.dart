import 'package:hive_ce/hive.dart';

part 'transport.g.dart';

/// A single dispatched product row. Cement is no longer represented as a
/// row here (moved to its own dedicated field on TransportEntry below) -
/// the isCement/reduceFromStock fields remain only so old saved entries
/// (from before this change) still read back correctly; new rows are
/// always products (isCement stays false).
@HiveType(typeId: 10)
class TransportItemRow {
  @HiveField(0)
  bool isCement; // legacy - kept for backward compatibility with old data

  @HiveField(1)
  String? categoryId;

  @HiveField(2)
  String? subcategoryId;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  bool reduceFromStock; // legacy - see cementReduceFromStock on TransportEntry for new cement entries

  TransportItemRow({
    this.isCement = false,
    this.categoryId,
    this.subcategoryId,
    required this.quantity,
    this.reduceFromStock = true,
  });
}

@HiveType(typeId: 11)
class TransportEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String transporterId;

  @HiveField(3)
  String vehicleType;

  @HiveField(4)
  String vehicleNo;

  @HiveField(5)
  List<TransportItemRow> items;

  @HiveField(6)
  double transportCharge; // flat fee per trip

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String? locationName;

  @HiveField(10)
  String? clientName;

  @HiveField(11)
  double cementBagsDispatched; // 0 = none dispatched this trip

  @HiveField(12)
  bool cementReduceFromStock; // default true; false = borrowed/friend factory stock

  TransportEntry({
    required this.id,
    required this.date,
    required this.transporterId,
    required this.vehicleType,
    required this.vehicleNo,
    required this.items,
    this.transportCharge = 0,
    this.notes,
    DateTime? createdAt,
    this.locationName,
    this.clientName,
    this.cementBagsDispatched = 0,
    this.cementReduceFromStock = true,
  }) : createdAt = createdAt ?? DateTime.now();
}
