import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/wishlist_item.dart';
import '../localization/app_strings.dart';
import 'add_wishlist_screen.dart';
import 'add_clothing_screen.dart';
import 'add_makeup_screen.dart';
import 'add_skincare_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteSelected(Box<WishlistItem> box) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_item_title')),
        content: Text(tr('delete_selected_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              final itemsToDelete = box.values.where((item) => _selectedIds.contains(item.id)).toList();
              for (final item in itemsToDelete) {
                item.delete();
              }
              Navigator.pop(context);
              _cancelSelection();
            },
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handlePurchased(BuildContext context, WishlistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('mark_purchased')),
        content: Text(tr('purchased_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              Widget targetScreen;
              if (item.type == tr('type_beauty')) {
                targetScreen = AddMakeupScreen(initialName: item.name);
              } else if (item.type == tr('type_skincare')) {
                targetScreen = AddSkincareScreen(initialName: item.name);
              } else {
                targetScreen = AddClothingScreen(initialName: item.name);
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetScreen),
              ).then((_) {
                item.delete();
              });
            },
            child: Text(tr('yes')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<WishlistItem>('wishlistBox');

    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelection,
              ),
              title: Text('${_selectedIds.length} ${tr('selection_mode_title')}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteSelected(box),
                ),
              ],
            )
          : AppBar(title: Text(tr('wishlist_title'))),
      body: AnimatedBuilder(
        animation: currentLanguage,
        builder: (context, _) {
          return ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<WishlistItem> box, _) {
              if (box.values.isEmpty) {
                return Center(child: Text(tr('wishlist_empty')));
              }

              final items = box.values.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = _selectedIds.contains(item.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: isSelected
                        ? RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFB185A7), width: 2),
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    child: ListTile(
                      leading: _selectionMode
                          ? Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? const Color(0xFFB185A7) : Colors.grey,
                            )
                          : const CircleAvatar(
                              backgroundColor: Color(0xFFF3E5F5),
                              child: Icon(Icons.favorite, color: Color(0xFFB185A7)),
                            ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        item.estimatedPrice != null
                            ? '${item.type} • ~${item.estimatedPrice!.toStringAsFixed(2)}₺'
                            : item.type,
                      ),
                      trailing: _selectionMode
                          ? null
                          : PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  item.delete();
                                } else if (value == 'purchased') {
                                  _handlePurchased(context, item);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'purchased',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(tr('mark_purchased')),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(tr('delete')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      onTap: () {
                        if (_selectionMode) {
                          _toggleSelection(item.id);
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(item.name),
                              content: Text(item.note ?? (item.link ?? '-')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(tr('cancel')),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_selectionMode) _enterSelectionMode(item.id);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddWishlistScreen()),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}