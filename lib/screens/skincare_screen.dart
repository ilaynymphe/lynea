import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/skincare_item.dart';
import '../localization/app_strings.dart';
import '../widgets/platform_image.dart';
import 'add_skincare_screen.dart';

class SkincareScreen extends StatefulWidget {
  const SkincareScreen({super.key});

  @override
  State<SkincareScreen> createState() => _SkincareScreenState();
}

class _SkincareScreenState extends State<SkincareScreen> {
  String _searchQuery = '';
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

  void _deleteSelected(Box<SkincareItem> box) {
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

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<SkincareItem>('skincareBox');

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
          : AppBar(title: Text(tr('skincare_title'))),
      body: AnimatedBuilder(
        animation: currentLanguage,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: tr('search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF3E5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: box.listenable(),
                  builder: (context, Box<SkincareItem> box, _) {
                    var items = box.values.toList();

                    if (_searchQuery.isNotEmpty) {
                      items = items.where((item) {
                        return item.name.toLowerCase().contains(_searchQuery) ||
                            item.brand.toLowerCase().contains(_searchQuery) ||
                            item.category.toLowerCase().contains(_searchQuery) ||
                            item.skinType.toLowerCase().contains(_searchQuery);
                      }).toList();
                    }

                    if (items.isEmpty) {
                      return Center(
                        child: Text(_searchQuery.isNotEmpty ? tr('search_no_results') : tr('skincare_empty')),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = _selectedIds.contains(item.id);

                        final now = DateTime.now();
                        final isExpiringSoon = item.expiryDate != null &&
                            item.expiryDate!.difference(now).inDays <= 30 &&
                            item.expiryDate!.difference(now).inDays >= 0;
                        final isExpired = item.expiryDate != null &&
                            item.expiryDate!.isBefore(now);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: isSelected
                              ? RoundedRectangleBorder(
                                  side: const BorderSide(color: Color(0xFFB185A7), width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: ListTile(
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelection(item.id);
                              }
                            },
                            onLongPress: () {
                              if (!_selectionMode) _enterSelectionMode(item.id);
                            },
                            leading: _selectionMode
                                ? Icon(
                                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                                    color: isSelected ? const Color(0xFFB185A7) : Colors.grey,
                                  )
                                : CircleAvatar(
                                    backgroundColor: const Color(0xFFF3E5F5),
                                    child: item.imagePath != null
                                        ? ClipOval(child: buildPickedImage(item.imagePath!))
                                        : const Icon(Icons.spa, color: Color(0xFFB185A7)),
                                  ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item.brand} • ${item.category} • ${item.skinType}'),
                            trailing: _selectionMode
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isExpired)
                                        const Icon(Icons.warning, color: Colors.red)
                                      else if (isExpiringSoon)
                                        const Icon(Icons.warning_amber, color: Colors.orange),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AddSkincareScreen(existingItem: item),
                                              ),
                                            );
                                          } else if (value == 'delete') {
                                            item.delete();
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.edit_outlined, size: 18),
                                                const SizedBox(width: 8),
                                                Text(tr('edit')),
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
                                    ],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSkincareScreen()),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}