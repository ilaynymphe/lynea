import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';
import '../localization/app_strings.dart';
import '../services/barcode_lookup_service.dart';
import '../widgets/platform_image.dart';
import 'barcode_scanner_screen.dart';

class AddClothingScreen extends StatefulWidget {
  final ClothingItem? existingItem;
  final String? initialName;

  const AddClothingScreen({super.key, this.existingItem, this.initialName});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _colorController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _purchasedFromController;
  late TextEditingController _noteController;

  late String _selectedCategoryKey;
  late String _selectedSeasonKey;
  late String _selectedCondition;
  String? _pickedImagePath;
  bool _scanningBarcode = false;
  bool _showMoreDetails = false;

  final List<String> _categoryKeys = [
    'tshirt', 'shirt', 'sweatshirt', 'hoodie', 'pants',
    'shorts', 'skirt', 'dress', 'jacket', 'coat',
    'shoes', 'bag', 'jewelry', 'hat', 'belt', 'accessory',
  ];

  final List<String> _seasonKeys = ['spring', 'summer', 'autumn', 'winter', 'all'];

  bool get _isEditing => widget.existingItem != null;

  String _categoryKeyFromLabel(String label) {
    for (final key in _categoryKeys) {
      if (tr('cat_$key') == label) return key;
    }
    return _categoryKeys.first;
  }

  String _seasonKeyFromLabel(String label) {
    for (final key in _seasonKeys) {
      if (tr('season_$key') == label) return key;
    }
    return _seasonKeys.first;
  }

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? widget.initialName ?? '');
    _colorController = TextEditingController(text: item?.color ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _priceController = TextEditingController(text: item?.purchasePrice?.toString() ?? '');
    _purchasedFromController = TextEditingController(text: item?.purchasedFrom ?? '');
    _noteController = TextEditingController(text: item?.note ?? '');
    _selectedCategoryKey = item != null ? _categoryKeyFromLabel(item.category) : 'tshirt';
    _selectedSeasonKey = item != null ? _seasonKeyFromLabel(item.season) : 'summer';
    _selectedCondition = item?.condition ?? 'new';
    _pickedImagePath = item?.imagePath;

    if (item != null &&
        ((item.brand != null && item.brand!.isNotEmpty) ||
            item.purchasePrice != null ||
            (item.purchasedFrom != null && item.purchasedFrom!.isNotEmpty) ||
            (item.note != null && item.note!.isNotEmpty))) {
      _showMoreDetails = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _purchasedFromController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (code == null) return;

    setState(() {
      _scanningBarcode = true;
    });

    final product = await BarcodeLookupService.lookupClothing(code);

    if (!mounted) return;

    setState(() {
      _scanningBarcode = false;
    });

    if (product == null || (product.name == null && product.brand == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('barcode_not_found'))),
      );
      return;
    }

    setState(() {
      if (product.name != null && product.name!.isNotEmpty) {
        _nameController.text = product.name!;
      }
      if (product.brand != null && product.brand!.isNotEmpty) {
        _brandController.text = product.brand!;
        _showMoreDetails = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('barcode_found'))),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(tr('choose_from_gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(tr('take_photo')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _pickedImagePath = picked.path;
      });
    }
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<ClothingItem>('clothingBox');

      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());

      if (_isEditing) {
        final item = widget.existingItem!;
        item.name = _nameController.text.trim();
        item.category = tr('cat_$_selectedCategoryKey');
        item.color = _colorController.text.trim();
        item.season = tr('season_$_selectedSeasonKey');
        item.imagePath = _pickedImagePath;
        item.brand = _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
        item.purchasePrice = price;
        item.purchasedFrom = _purchasedFromController.text.trim().isEmpty
            ? null
            : _purchasedFromController.text.trim();
        item.condition = _selectedCondition;
        item.note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
        item.save();
      } else {
        final newItem = ClothingItem(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          category: tr('cat_$_selectedCategoryKey'),
          color: _colorController.text.trim(),
          season: tr('season_$_selectedSeasonKey'),
          imagePath: _pickedImagePath,
          dateAdded: DateTime.now(),
          brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          purchasePrice: price,
          purchasedFrom: _purchasedFromController.text.trim().isEmpty
              ? null
              : _purchasedFromController.text.trim(),
          condition: _selectedCondition,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
        box.add(newItem);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ ${tr('form_save')}!'), duration: const Duration(seconds: 1)),
      );
      Navigator.pop(context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? tr('edit') : tr('add_clothing_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: _scanningBarcode ? null : _scanBarcode,
                    icon: _scanningBarcode
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code_scanner),
                    label: Text(tr('scan_barcode_title')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _pickedImagePath == null
                      ? const Center(
                          child: Icon(Icons.add_a_photo, size: 40, color: Color(0xFFB185A7)),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildPickedImage(_pickedImagePath!),
                        ),
                ),
              ),
              const SizedBox(height: 16),
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
                initialValue: _selectedCategoryKey,
                decoration: InputDecoration(labelText: tr('form_category')),
                items: _categoryKeys.map((key) {
                  return DropdownMenuItem(value: key, child: Text(tr('cat_$key')));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryKey = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(labelText: tr('form_color')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('form_error_color');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSeasonKey,
                decoration: InputDecoration(labelText: tr('form_season')),
                items: _seasonKeys.map((key) {
                  return DropdownMenuItem(value: key, child: Text(tr('season_$key')));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSeasonKey = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() => _showMoreDetails = !_showMoreDetails),
                icon: Icon(_showMoreDetails ? Icons.expand_less : Icons.expand_more),
                label: Text(_showMoreDetails ? tr('hide_more_details') : tr('show_more_details')),
              ),
              if (_showMoreDetails) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(labelText: tr('form_brand')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: tr('form_purchase_price')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purchasedFromController,
                  decoration: InputDecoration(labelText: tr('form_purchased_from')),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  decoration: InputDecoration(labelText: tr('form_condition')),
                  items: [
                    DropdownMenuItem(value: 'new', child: Text(tr('condition_new'))),
                    DropdownMenuItem(value: 'used', child: Text(tr('condition_used'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCondition = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(labelText: tr('form_note')),
                  maxLines: 2,
                ),
              ],
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