import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../localization/app_strings.dart';
import '../widgets/platform_image.dart';
import 'add_clothing_screen.dart';

class ClothingDetailScreen extends StatefulWidget {
  final ClothingItem item;

  const ClothingDetailScreen({super.key, required this.item});

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  void _toggleFavorite() {
    setState(() {
      widget.item.isFavorite = !widget.item.isFavorite;
    });
    widget.item.save();
  }

  void _deleteItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_item_title')),
        content: Text('${widget.item.name} ${tr('delete_item_confirm')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              widget.item.delete();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markUsedToday() {
    final now = DateTime.now();
    final alreadyToday = widget.item.usageDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );

    if (alreadyToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('already_marked_today'))),
      );
      return;
    }

    setState(() {
      widget.item.usageDates.add(now);
    });
    widget.item.save();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('marked_used_today'))),
    );
  }

  String _lastUsedText() {
    final dates = widget.item.usageDates;
    if (dates.isEmpty) return tr('never_used');
    final sorted = List<DateTime>.from(dates)..sort();
    final last = sorted.last;
    return '${last.day}/${last.month}/${last.year}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AnimatedBuilder(
      animation: currentLanguage,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(item.name),
            actions: [
              IconButton(
                icon: Icon(
                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: item.isFavorite ? Colors.red : null,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddClothingScreen(existingItem: item),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteItem,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: item.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: buildPickedImage(item.imagePath!),
                      )
                    : const Icon(Icons.checkroom, size: 80, color: Color(0xFFB185A7)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _markUsedToday,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(tr('mark_used_today')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(label: tr('detail_name'), value: item.name),
              _DetailRow(label: tr('detail_category'), value: item.category),
              _DetailRow(label: tr('detail_color'), value: item.color),
              _DetailRow(label: tr('detail_season'), value: item.season),
              if (item.brand != null && item.brand!.isNotEmpty)
                _DetailRow(label: tr('detail_brand'), value: item.brand!),
              if (item.purchasePrice != null)
                _DetailRow(
                  label: tr('detail_purchase_price'),
                  value: '${item.purchasePrice!.toStringAsFixed(2)}₺',
                ),
              if (item.purchasedFrom != null && item.purchasedFrom!.isNotEmpty)
                _DetailRow(label: tr('detail_purchased_from'), value: item.purchasedFrom!),
              _DetailRow(
                label: tr('detail_condition'),
                value: item.condition == 'new' ? tr('condition_new') : tr('condition_used'),
              ),
              if (item.note != null && item.note!.isNotEmpty)
                _DetailRow(label: tr('detail_note'), value: item.note!),
              _DetailRow(
                label: tr('detail_date_added'),
                value: '${item.dateAdded.day}/${item.dateAdded.month}/${item.dateAdded.year}',
              ),
              _DetailRow(
                label: tr('detail_usage_count'),
                value: '${item.usageDates.length}',
              ),
              _DetailRow(
                label: tr('detail_last_used'),
                value: _lastUsedText(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}