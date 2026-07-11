// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clothing_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClothingItemAdapter extends TypeAdapter<ClothingItem> {
  @override
  final int typeId = 0;

  @override
  ClothingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClothingItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      color: fields[3] as String,
      season: fields[4] as String,
      imagePath: fields[5] as String?,
      isFavorite: fields[6] as bool,
      dateAdded: fields[7] as DateTime,
      brand: fields[8] as String?,
      purchasePrice: fields[9] as double?,
      purchasedFrom: fields[10] as String?,
      condition: fields[11] as String?,
      note: fields[12] as String?,
      usageDates: (fields[13] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, ClothingItem obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.season)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.dateAdded)
      ..writeByte(8)
      ..write(obj.brand)
      ..writeByte(9)
      ..write(obj.purchasePrice)
      ..writeByte(10)
      ..write(obj.purchasedFrom)
      ..writeByte(11)
      ..write(obj.condition)
      ..writeByte(12)
      ..write(obj.note)
      ..writeByte(13)
      ..write(obj.usageDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
