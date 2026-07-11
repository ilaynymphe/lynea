import 'package:hive/hive.dart';

part 'outfit.g.dart';

@HiveType(typeId: 4)
class Outfit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String occasion;

  @HiveField(3)
  List<String> clothingItemIds;

  @HiveField(4)
  DateTime dateCreated;

  @HiveField(5)
  List<DateTime> wornDates;

  Outfit({
    required this.id,
    required this.name,
    required this.occasion,
    required this.clothingItemIds,
    required this.dateCreated,
    List<DateTime>? wornDates,
  }) : wornDates = wornDates ?? [];

  // Firestore'a göndermek için bu nesneyi Map'e çevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'occasion': occasion,
      'clothingItemIds': clothingItemIds,
      'dateCreated': dateCreated.toIso8601String(),
      'wornDates': wornDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  // Firestore'dan gelen Map'i bu nesneye çevirir
  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'] as String,
      name: json['name'] as String,
      occasion: json['occasion'] as String,
      clothingItemIds: (json['clothingItemIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      wornDates: (json['wornDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }
}