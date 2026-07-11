import 'dart:convert';
import 'package:http/http.dart' as http;

class BarcodeProduct {
  final String? name;
  final String? brand;

  BarcodeProduct({this.name, this.brand});
}

class BarcodeLookupService {
  static Future<BarcodeProduct?> lookupBeautyOrSkincare(String barcode) async {
    try {
      final url = Uri.parse('https://world.openbeautyfacts.org/api/v2/product/$barcode.json');
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 1) return null;

      final product = data['product'];
      return BarcodeProduct(
        name: product['product_name'] as String?,
        brand: product['brands'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<BarcodeProduct?> lookupClothing(String barcode) async {
    try {
      final url = Uri.parse('https://world.openproductsfacts.org/api/v2/product/$barcode.json');
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 1) return null;

      final product = data['product'];
      return BarcodeProduct(
        name: product['product_name'] as String?,
        brand: product['brands'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}