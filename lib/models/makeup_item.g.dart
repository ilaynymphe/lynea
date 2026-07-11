// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'makeup_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MakeupItemAdapter extends TypeAdapter<MakeupItem> {
  @override
  final int typeId = 1;

  @override
  MakeupItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MakeupItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      brand: fields[3] as String,
      shade: fields[4] as String,
      expiryDate: fields[5] as DateTime?,
      imagePath: fields[6] as String?,
      isFavorite: fields[7] as bool,
      dateAdded: fields[8] as DateTime,
      purchasePrice: fields[9] as double?,
      note: fields[10] as String?,
      usageDates: (fields[11] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, MakeupItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.brand)
      ..writeByte(4)
      ..write(obj.shade)
      ..writeByte(5)
      ..write(obj.expiryDate)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.dateAdded)
      ..writeByte(9)
      ..write(obj.purchasePrice)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.usageDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MakeupItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
