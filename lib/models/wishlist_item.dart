import 'package:hive/hive.dart';

part 'wishlist_item.g.dart';

@HiveType(typeId: 3)
class WishlistItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // wardrobe, beauty, skincare

  @HiveField(3)
  double? estimatedPrice;

  @HiveField(4)
  String? note;

  @HiveField(5)
  String? link;

  @HiveField(6)
  DateTime dateAdded;

  WishlistItem({
    required this.id,
    required this.name,
    required this.type,
    this.estimatedPrice,
    this.note,
    this.link,
    required this.dateAdded,
  });

  // Firestore'a göndermek için bu nesneyi Map'e çevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'estimatedPrice': estimatedPrice,
      'note': note,
      'link': link,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  // Firestore'dan gelen Map'i bu nesneye çevirir
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      note: json['note'] as String?,
      link: json['link'] as String?,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
    );
  }
}