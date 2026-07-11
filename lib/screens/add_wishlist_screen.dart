import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/wishlist_item.dart';
import '../localization/app_strings.dart';


class AddWishlistScreen extends StatefulWidget {
  const AddWishlistScreen({super.key});

  @override
  State<AddWishlistScreen> createState() => _AddWishlistScreenState();
}

class _AddWishlistScreenState extends State<AddWishlistScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedTypeKey = 'wardrobe';

  final List<String> _typeKeys = ['wardrobe', 'beauty', 'skincare'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<WishlistItem>('wishlistBox');

      final newItem = WishlistItem(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        type: tr('type_$_selectedTypeKey'),
        estimatedPrice: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        dateAdded: DateTime.now(),
      );

      box.add(newItem);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('add_wishlist_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: tr('form_name')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('form_error_name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedTypeKey,
                decoration: InputDecoration(labelText: tr('form_type')),
                items: _typeKeys.map((key) {
                  return DropdownMenuItem(value: key, child: Text(tr('type_$key')));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypeKey = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: tr('form_estimated_price')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: tr('form_note')),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(labelText: tr('form_link')),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(tr('form_save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}