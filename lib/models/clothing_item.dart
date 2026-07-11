import 'package:hive/hive.dart';

part 'clothing_item.g.dart';

@HiveType(typeId: 0)
class ClothingItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  String color;

  @HiveField(4)
  String season;

  @HiveField(5)
  String? imagePath;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  DateTime dateAdded;

  @HiveField(8)
  String? brand;

  @HiveField(9)
  double? purchasePrice;

  @HiveField(10)
  String? purchasedFrom;

  @HiveField(11)
  String? condition;

  @HiveField(12)
  String? note;

  @HiveField(13)
  List<DateTime> usageDates;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.season,
    this.imagePath,
    this.isFavorite = false,
    required this.dateAdded,
    this.brand,
    this.purchasePrice,
    this.purchasedFrom,
    this.condition,
    this.note,
    List<DateTime>? usageDates,
  }) : usageDates = usageDates ?? [];

  // Firestore'a göndermek için bu nesneyi Map'e çevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'season': season,
      'imagePath': imagePath,
      'isFavorite': isFavorite,
      'dateAdded': dateAdded.toIso8601String(),
      'brand': brand,
      'purchasePrice': purchasePrice,
      'purchasedFrom': purchasedFrom,
      'condition': condition,
      'note': note,
      'usageDates': usageDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  // Firestore'dan gelen Map'i bu nesneye çevirir
  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      color: json['color'] as String,
      season: json['season'] as String,
      imagePath: json['imagePath'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      brand: json['brand'] as String?,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      purchasedFrom: json['purchasedFrom'] as String?,
      condition: json['condition'] as String?,
      note: json['note'] as String?,
      usageDates: (json['usageDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }
}