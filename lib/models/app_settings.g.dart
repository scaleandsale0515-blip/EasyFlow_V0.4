part of 'app_settings.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 13;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      adminIdHash: fields[0] as String,
      adminPasswordHash: fields[1] as String,
      salt: fields[2] as String,
      openingCementStock: (fields[3] as num).toDouble(),
      openingStockSet: fields[4] as bool,
      lowStockThreshold: (fields[5] as num).toDouble(),
      lastBackupDate: fields[6] as DateTime?,
      isActivated: fields[7] as bool? ?? false,
      isDarkMode: fields[8] as bool? ?? true,
      showProductionChart: fields[9] as bool? ?? true,
      showWorkerChart: fields[10] as bool? ?? true,
      showTrendsChart: fields[11] as bool? ?? true,
      showPurchaseUsageChart: fields[12] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.adminIdHash)
      ..writeByte(1)
      ..write(obj.adminPasswordHash)
      ..writeByte(2)
      ..write(obj.salt)
      ..writeByte(3)
      ..write(obj.openingCementStock)
      ..writeByte(4)
      ..write(obj.openingStockSet)
      ..writeByte(5)
      ..write(obj.lowStockThreshold)
      ..writeByte(6)
      ..write(obj.lastBackupDate)
      ..writeByte(7)
      ..write(obj.isActivated)
      ..writeByte(8)
      ..write(obj.isDarkMode)
      ..writeByte(9)
      ..write(obj.showProductionChart)
      ..writeByte(10)
      ..write(obj.showWorkerChart)
      ..writeByte(11)
      ..write(obj.showTrendsChart)
      ..writeByte(12)
      ..write(obj.showPurchaseUsageChart);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
