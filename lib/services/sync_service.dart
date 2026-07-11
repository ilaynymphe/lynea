import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import '../models/makeup_item.dart';
import '../models/skincare_item.dart';
import '../models/wishlist_item.dart';
import '../models/outfit.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tüm kutuları sırayla senkronize eden ana fonksiyon
  Future<void> syncAll() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    await _syncBox<ClothingItem>(boxName: 'clothingBox', remoteCollectionName: 'clothing', uid: uid);
    await _syncBox<MakeupItem>(boxName: 'makeupBox', remoteCollectionName: 'makeup', uid: uid);
    await _syncBox<SkincareItem>(boxName: 'skincareBox', remoteCollectionName: 'skincare', uid: uid);
    await _syncBox<WishlistItem>(boxName: 'wishlistBox', remoteCollectionName: 'wishlist', uid: uid);
    await _syncBox<Outfit>(boxName: 'outfitBox', remoteCollectionName: 'outfit', uid: uid);
  }

  // Genelleştirilmiş iki yönlü senkronizasyon fonksiyonu
  Future<void> _syncBox<T>({
    required String boxName, 
    required String remoteCollectionName, 
    required String uid,
  }) async {
    final box = Hive.box<T>(boxName);
    final userDocRef = _firestore.collection('users').doc(uid);
    final collectionRef = userDocRef.collection(remoteCollectionName);

    // 1. Yerel (Hive) verileri al ve Firestore'a yükle/güncelle
    final localItems = box.toMap();
    for (var entry in localItems.entries) {
      final key = entry.key.toString();
      final item = entry.value;

      if (item != null) {
        final Map<String, dynamic> data = _toJson(item, remoteCollectionName);
        if (data.isNotEmpty) {
          await collectionRef.doc(key).set(data);
        }
      }
    }

    // 2. Bulut (Firestore) verilerini al ve Yerel (Hive) kutuya yaz
    final remoteSnapshot = await collectionRef.get();
    for (var doc in remoteSnapshot.docs) {
      final key = doc.id;
      final data = doc.data();

      final dynamic item = _fromJson(data, remoteCollectionName);
      if (item != null) {
        final parsedKey = int.tryParse(key) ?? key;
        await box.put(parsedKey, item);
      }
    }
  }

  // Model nesnelerini tiplerine göre toJson metotlarına yönlendirir
  Map<String, dynamic> _toJson(dynamic item, String collectionName) {
    if (collectionName == 'clothing') return (item as ClothingItem).toJson();
    if (collectionName == 'skincare') return (item as SkincareItem).toJson();
    if (collectionName == 'wishlist') return (item as WishlistItem).toJson();
    if (collectionName == 'outfit') return (item as Outfit).toJson();
    if (collectionName == 'makeup') {
      final m = item as MakeupItem;
      return {
        'id': m.id,
        'name': m.name,
        'category': m.category,
        'brand': m.brand,
        'shade': m.shade,
        'expiryDate': m.expiryDate?.toIso8601String(),
        'imagePath': m.imagePath,
        'isFavorite': m.isFavorite,
        'dateAdded': m.dateAdded.toIso8601String(),
        'purchasePrice': m.purchasePrice,
        'note': m.note,
        'usageDates': m.usageDates.map((d) => d.toIso8601String()).toList(),
      };
    }
    return {};
  }

  // Firestore verilerini tiplerine göre model nesnelerine dönüştürür
  dynamic _fromJson(Map<String, dynamic> data, String collectionName) {
    if (collectionName == 'clothing') return ClothingItem.fromJson(data);
    if (collectionName == 'skincare') return SkincareItem.fromJson(data);
    if (collectionName == 'wishlist') return WishlistItem.fromJson(data);
    if (collectionName == 'outfit') return Outfit.fromJson(data);
    if (collectionName == 'makeup') {
      return MakeupItem(
        id: data['id'] as String,
        name: data['name'] as String,
        category: data['category'] as String,
        brand: data['brand'] as String,
        shade: data['shade'] as String,
        expiryDate: data['expiryDate'] != null ? DateTime.parse(data['expiryDate'] as String) : null,
        imagePath: data['imagePath'] as String?,
        isFavorite: data['isFavorite'] as bool? ?? false,
        dateAdded: DateTime.parse(data['dateAdded'] as String),
        purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
        note: data['note'] as String?,
        usageDates: (data['usageDates'] as List<dynamic>?)?.map((d) => DateTime.parse(d as String)).toList(),
      );
    }
    return null;
  }
}