import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
import '../localization/app_strings.dart';

class OutfitStudioScreen extends StatefulWidget {
  const OutfitStudioScreen({super.key});

  @override
  State<OutfitStudioScreen> createState() => _OutfitStudioScreenState();
}

class _OutfitStudioScreenState extends State<OutfitStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('outfit_studio_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('outfit_studio_title')),
            Tab(text: tr('view_calendar')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OutfitListTab(),
          _OutfitCalendarTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return _tabController.index == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateOutfitScreen()),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OutfitListTab extends StatelessWidget {
  const _OutfitListTab();

  @override
  Widget build(BuildContext context) {
    final outfitBox = Hive.box<Outfit>('outfitBox');
    final clothingBox = Hive.box<ClothingItem>('clothingBox');

    return AnimatedBuilder(
      animation: currentLanguage,
      builder: (context, _) {
        return ValueListenableBuilder(
          valueListenable: outfitBox.listenable(),
          builder: (context, Box<Outfit> box, _) {
            if (box.values.isEmpty) {
              return Center(child: Text(tr('outfit_empty')));
            }

            final outfits = box.values.toList();

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: outfits.length,
              itemBuilder: (context, index) {
                final outfit = outfits[index];

                final items = outfit.clothingItemIds
                    .map((id) {
                      try {
                        return clothingBox.values.firstWhere((c) => c.id == id);
                      } catch (_) {
                        return null;
                      }
                    })
                    .whereType<ClothingItem>()
                    .toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                outfit.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  outfit.delete();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          outfit.occasion,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        if (items.isEmpty)
                          Text(
                            tr('outfit_empty'),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        else
                          SizedBox(
                            height: 70,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (context, i) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return Container(
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: item.imagePath != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(item.imagePath!, fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.checkroom, color: Color(0xFFB185A7)),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${outfit.wornDates.length} ${tr('worn_count')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                final today = DateTime.now();
                                final todayNormalized = DateTime(today.year, today.month, today.day);
                                final alreadyMarked = outfit.wornDates.any((d) =>
                                    d.year == todayNormalized.year &&
                                    d.month == todayNormalized.month &&
                                    d.day == todayNormalized.day);
                                if (!alreadyMarked) {
                                  outfit.wornDates.add(todayNormalized);
                                  outfit.save();
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: Text(tr('mark_as_worn'), style: const TextStyle(fontSize: 12)),
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
        );
      },
    );
  }
}

class _OutfitCalendarTab extends StatefulWidget {
  const _OutfitCalendarTab();

  @override
  State<_OutfitCalendarTab> createState() => _OutfitCalendarTabState();
}

class _OutfitCalendarTabState extends State<_OutfitCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Outfit> _outfitsForDay(DateTime day, Box<Outfit> box) {
    final normalized = DateTime(day.year, day.month, day.day);
    return box.values.where((outfit) {
      return outfit.wornDates.any((d) =>
          d.year == normalized.year && d.month == normalized.month && d.day == normalized.day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final outfitBox = Hive.box<Outfit>('outfitBox');

    return ValueListenableBuilder(
      valueListenable: outfitBox.listenable(),
      builder: (context, Box<Outfit> box, _) {
        final selectedOutfits = _selectedDay != null ? _outfitsForDay(_selectedDay!, box) : <Outfit>[];

        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) => _outfitsForDay(day, box),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFFE7A9C7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFFB185A7),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFFB185A7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedDay == null
                  ? Center(child: Text(tr('select_outfit')))
                  : selectedOutfits.isEmpty
                      ? Center(child: Text(tr('no_outfit_for_date')))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: selectedOutfits.length,
                          itemBuilder: (context, index) {
                            final outfit = selectedOutfits[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.checkroom, color: Color(0xFFB185A7)),
                                title: Text(outfit.name),
                                subtitle: Text(outfit.occasion),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class CreateOutfitScreen extends StatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  final _nameController = TextEditingController();
  String _selectedOccasionKey = 'campus';
  final Set<String> _selectedItemIds = {};

  final List<String> _occasionKeys = ['campus', 'summer', 'evening', 'work', 'party'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveOutfit() {
    if (_nameController.text.trim().isEmpty || _selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('form_error_name'))),
      );
      return;
    }

    final box = Hive.box<Outfit>('outfitBox');

    final newOutfit = Outfit(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      occasion: tr('occasion_$_selectedOccasionKey'),
      clothingItemIds: _selectedItemIds.toList(),
      dateCreated: DateTime.now(),
    );

    box.add(newOutfit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final clothingBox = Hive.box<ClothingItem>('clothingBox');

    return Scaffold(
      appBar: AppBar(title: Text(tr('create_outfit'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: tr('outfit_name')),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedOccasionKey,
                  decoration: InputDecoration(labelText: tr('form_type')),
                  items: _occasionKeys.map((key) {
                    return DropdownMenuItem(value: key, child: Text(tr('occasion_$key')));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOccasionKey = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${tr('select_items')} (${_selectedItemIds.length} ${tr('selected_count')})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: clothingBox.listenable(),
              builder: (context, Box<ClothingItem> box, _) {
                if (box.values.isEmpty) {
                  return Center(child: Text(tr('no_clothing_yet')));
                }

                final items = box.values.toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedItemIds.contains(item.id);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedItemIds.remove(item.id);
                          } else {
                            _selectedItemIds.add(item.id);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFB185A7) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: item.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(item.imagePath!, fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.checkroom, color: Color(0xFFB185A7)),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(Icons.check_circle, color: Color(0xFFB185A7), size: 20),
                              ),
                            Positioned(
                              bottom: 2,
                              left: 2,
                              right: 2,
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveOutfit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(tr('form_save')),
            ),
          ),
        ],
      ),
    );
  }
}