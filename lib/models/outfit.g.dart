// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutfitAdapter extends TypeAdapter<Outfit> {
  @override
  final int typeId = 4;

  @override
  Outfit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Outfit(
      id: fields[0] as String,
      name: fields[1] as String,
      occasion: fields[2] as String,
      clothingItemIds: (fields[3] as List).cast<String>(),
      dateCreated: fields[4] as DateTime,
      wornDates: (fields[5] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, Outfit obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.occasion)
      ..writeByte(3)
      ..write(obj.clothingItemIds)
      ..writeByte(4)
      ..write(obj.dateCreated)
      ..writeByte(5)
      ..write(obj.wornDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
