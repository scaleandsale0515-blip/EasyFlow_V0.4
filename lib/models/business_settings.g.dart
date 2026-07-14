part of 'business_settings.dart';

class BusinessSettingsAdapter extends TypeAdapter<BusinessSettings> {
  @override
  final int typeId = 14;

  @override
  BusinessSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusinessSettings(
      openingCementStock: (fields[0] as num?)?.toDouble() ?? 0,
      openingStockSet: fields[1] as bool? ?? false,
      lowStockThreshold: (fields[2] as num?)?.toDouble() ?? 50,
    );
  }

  @override
  void write(BinaryWriter writer, BusinessSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.openingCementStock)
      ..writeByte(1)
      ..write(obj.openingStockSet)
      ..writeByte(2)
      ..write(obj.lowStockThreshold);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
