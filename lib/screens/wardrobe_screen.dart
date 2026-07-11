import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import '../localization/app_strings.dart';
import '../widgets/platform_image.dart';
import 'add_clothing_screen.dart';
import 'clothing_detail_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  String? _selectedColor;
  bool _favoritesOnly = false;
  bool _rarelyUsedOnly = false;

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  static const int _unusedThresholdDays = 30;

  List<String> get _categoryKeys => [
        'all', 'tshirt', 'shirt', 'sweatshirt', 'hoodie', 'pants',
        'shorts', 'skirt', 'dress', 'jacket', 'coat',
        'shoes', 'bag', 'jewelry', 'hat', 'belt', 'accessory',
      ];

  String _categoryLabel(String key) => tr('cat_$key');

  bool _isRarelyUsed(ClothingItem item) {
    final now = DateTime.now();
    if (item.usageDates.isEmpty) {
      return now.difference(item.dateAdded).inDays >= _unusedThresholdDays;
    }
    final sorted = List<DateTime>.from(item.usageDates)..sort();
    final last = sorted.last;
    return now.difference(last).inDays >= _unusedThresholdDays;
  }

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

  void _deleteSelected(Box<ClothingItem> box) {
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

  void _openFilterSheet(List<String> availableColors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('filters'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedColor,
                    decoration: InputDecoration(labelText: tr('form_color')),
                    items: [
                      DropdownMenuItem(value: null, child: Text(tr('filter_all_colors'))),
                      ...availableColors.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedColor = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('filter_favorites_only')),
                    value: _favoritesOnly,
                    onChanged: (value) {
                      setModalState(() {
                        _favoritesOnly = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('filter_rarely_used')),
                    value: _rarelyUsedOnly,
                    onChanged: (value) {
                      setModalState(() {
                        _rarelyUsedOnly = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedColor = null;
                              _favoritesOnly = false;
                              _rarelyUsedOnly = false;
                            });
                          },
                          child: Text(tr('clear_filters')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: Text(tr('apply')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ClothingItem>('clothingBox');

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
          : AppBar(title: Text(tr('wardrobe_title'))),
      body: AnimatedBuilder(
        animation: currentLanguage,
        builder: (context, _) {
          return ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<ClothingItem> box, _) {
              final allItems = box.values.toList();
              final availableColors = allItems.map((e) => e.color).toSet().toList()..sort();

              var items = allItems;

              if (_selectedFilter != 'all') {
                final label = _categoryLabel(_selectedFilter);
                items = items.where((item) => item.category == label).toList();
              }

              if (_selectedColor != null) {
                items = items.where((item) => item.color == _selectedColor).toList();
              }

              if (_favoritesOnly) {
                items = items.where((item) => item.isFavorite).toList();
              }

              if (_rarelyUsedOnly) {
                items = items.where(_isRarelyUsed).toList();
              }

              if (_searchQuery.isNotEmpty) {
                items = items.where((item) {
                  return item.name.toLowerCase().contains(_searchQuery) ||
                      item.color.toLowerCase().contains(_searchQuery) ||
                      item.category.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _openFilterSheet(availableColors),
                          icon: Stack(
                            children: [
                              const Icon(Icons.tune),
                              if (_selectedColor != null || _favoritesOnly || _rarelyUsedOnly)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFB185A7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: _categoryKeys.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final key = _categoryKeys[index];
                        final isSelected = key == _selectedFilter;
                        return ChoiceChip(
                          label: Text(key == 'all' ? tr('cat_all') : _categoryLabel(key)),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = key;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? tr('search_no_results')
                                  : _selectedFilter == 'all'
                                      ? tr('wardrobe_empty')
                                      : tr('wardrobe_empty_category'),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isSelected = _selectedIds.contains(item.id);
                              return GestureDetector(
                                onTap: () {
                                  if (_selectionMode) {
                                    _toggleSelection(item.id);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ClothingDetailScreen(item: item),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  if (!_selectionMode) _enterSelectionMode(item.id);
                                },
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  shape: isSelected
                                      ? RoundedRectangleBorder(
                                          side: const BorderSide(color: Color(0xFFB185A7), width: 3),
                                          borderRadius: BorderRadius.circular(4),
                                        )
                                      : null,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              color: const Color(0xFFF3E5F5),
                                              width: double.infinity,
                                              height: double.infinity,
                                              child: item.imagePath != null
                                                  ? buildPickedImage(item.imagePath!)
                                                  : const Icon(Icons.checkroom, size: 40, color: Color(0xFFB185A7)),
                                            ),
                                            if (item.isFavorite && !_selectionMode)
                                              const Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Icon(Icons.favorite, color: Colors.red, size: 18),
                                              ),
                                            if (_selectionMode)
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Icon(
                                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                                  color: isSelected ? const Color(0xFFB185A7) : Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              item.category,
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
                  MaterialPageRoute(builder: (context) => const AddClothingScreen()),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}