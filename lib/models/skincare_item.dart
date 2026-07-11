import 'package:hive/hive.dart';

part 'skincare_item.g.dart';

@HiveType(typeId: 2)
class SkincareItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  String brand;

  @HiveField(4)
  String skinType;

  @HiveField(5)
  DateTime? expiryDate;

  @HiveField(6)
  String? imagePath;

  @HiveField(7)
  bool isFavorite;

  @HiveField(8)
  DateTime dateAdded;

  @HiveField(9)
  double? purchasePrice;

  @HiveField(10)
  String? note;

  @HiveField(11)
  List<DateTime> usageDates;

  SkincareItem({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.skinType,
    this.expiryDate,
    this.imagePath,
    this.isFavorite = false,
    required this.dateAdded,
    this.purchasePrice,
    this.note,
    List<DateTime>? usageDates,
  }) : usageDates = usageDates ?? [];

  // Firestore'a göndermek için bu nesneyi Map'e çevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'skinType': skinType,
      'expiryDate': expiryDate?.toIso8601String(),
      'imagePath': imagePath,
      'isFavorite': isFavorite,
      'dateAdded': dateAdded.toIso8601String(),
      'purchasePrice': purchasePrice,
      'note': note,
      'usageDates': usageDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  // Firestore'dan gelen Map'i bu nesneye çevirir
  factory SkincareItem.fromJson(Map<String, dynamic> json) {
    return SkincareItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      skinType: json['skinType'] as String,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      imagePath: json['imagePath'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      note: json['note'] as String?,
      usageDates: (json['usageDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }
}