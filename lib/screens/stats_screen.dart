import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothing_item.dart';
import '../models/makeup_item.dart';
import '../models/skincare_item.dart';
import '../localization/app_strings.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const int _unusedThresholdDays = 30;
  static const double _colorWarningThreshold = 0.30;

  bool _isStale(List<DateTime> usageDates, DateTime dateAdded, DateTime now) {
    if (usageDates.isEmpty) {
      return now.difference(dateAdded).inDays >= _unusedThresholdDays;
    }
    final sorted = List<DateTime>.from(usageDates)..sort();
    final last = sorted.last;
    return now.difference(last).inDays >= _unusedThresholdDays;
  }

  @override
  Widget build(BuildContext context) {
    final clothingBox = Hive.box<ClothingItem>('clothingBox');
    final makeupBox = Hive.box<MakeupItem>('makeupBox');
    final skincareBox = Hive.box<SkincareItem>('skincareBox');

    return Scaffold(
      appBar: AppBar(title: Text(tr('stats_title'))),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          clothingBox.listenable(),
          makeupBox.listenable(),
          skincareBox.listenable(),
          currentLanguage,
        ]),
        builder: (context, _) {
          final totalClothing = clothingBox.values.length;
          final totalMakeup = makeupBox.values.length;
          final totalSkincare = skincareBox.values.length;
          final total = totalClothing + totalMakeup + totalSkincare;

          if (total == 0) {
            return Center(child: Text(tr('stats_empty')));
          }

          final now = DateTime.now();
          int expiringSoon = 0;
          int expired = 0;

          for (final item in makeupBox.values) {
            if (item.expiryDate != null) {
              final diff = item.expiryDate!.difference(now).inDays;
              if (diff < 0) {
                expired++;
              } else if (diff <= 30) {
                expiringSoon++;
              }
            }
          }
          for (final item in skincareBox.values) {
            if (item.expiryDate != null) {
              final diff = item.expiryDate!.difference(now).inDays;
              if (diff < 0) {
                expired++;
              } else if (diff <= 30) {
                expiringSoon++;
              }
            }
          }

          final staleItems = <_StaleEntry>[];

          for (final item in clothingBox.values) {
            if (_isStale(item.usageDates, item.dateAdded, now)) {
              staleItems.add(_StaleEntry(name: item.name, type: tr('stats_wardrobe')));
            }
          }
          for (final item in makeupBox.values) {
            if (_isStale(item.usageDates, item.dateAdded, now)) {
              staleItems.add(_StaleEntry(name: item.name, type: tr('stats_beauty')));
            }
          }
          for (final item in skincareBox.values) {
            if (_isStale(item.usageDates, item.dateAdded, now)) {
              staleItems.add(_StaleEntry(name: item.name, type: tr('stats_skincare')));
            }
          }

          String? dominantColor;
          double dominantRatio = 0;
          if (totalClothing > 0) {
            final colorCounts = <String, int>{};
            for (final item in clothingBox.values) {
              colorCounts[item.color] = (colorCounts[item.color] ?? 0) + 1;
            }
            final sortedColors = colorCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            if (sortedColors.isNotEmpty) {
              dominantColor = sortedColors.first.key;
              dominantRatio = sortedColors.first.value / totalClothing;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                tr('stats_total_items'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$total',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFB185A7)),
              ),
              const SizedBox(height: 24),
              Text(
                tr('stats_by_category'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: totalClothing.toDouble(),
                              color: const Color(0xFFB185A7),
                              title: '$totalClothing',
                              radius: 60,
                            ),
                            PieChartSectionData(
                              value: totalMakeup.toDouble(),
                              color: const Color(0xFFE7A9C7),
                              title: '$totalMakeup',
                              radius: 60,
                            ),
                            PieChartSectionData(
                              value: totalSkincare.toDouble(),
                              color: const Color(0xFFF3C7DC),
                              title: '$totalSkincare',
                              radius: 60,
                            ),
                          ],
                          sectionsSpace: 3,
                          centerSpaceRadius: 30,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendDot(color: const Color(0xFFB185A7), label: tr('stats_wardrobe')),
                          const SizedBox(height: 8),
                          _LegendDot(color: const Color(0xFFE7A9C7), label: tr('stats_beauty')),
                          const SizedBox(height: 8),
                          _LegendDot(color: const Color(0xFFF3C7DC), label: tr('stats_skincare')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _WarningCard(
                      icon: Icons.warning_amber,
                      color: Colors.orange,
                      label: tr('stats_expiring_soon'),
                      count: expiringSoon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WarningCard(
                      icon: Icons.warning,
                      color: Colors.red,
                      label: tr('stats_expired'),
                      count: expired,
                    ),
                  ),
                ],
              ),
              if (dominantColor != null) ...[
                const SizedBox(height: 24),
                Text(
                  tr('stats_color_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dominantRatio >= _colorWarningThreshold
                        ? Colors.orange.shade50
                        : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: dominantRatio >= _colorWarningThreshold
                        ? Border.all(color: Colors.orange.shade200)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: dominantRatio >= _colorWarningThreshold
                            ? Colors.orange
                            : const Color(0xFFB185A7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${(dominantRatio * 100).toStringAsFixed(0)}% ${tr('stats_color_of_wardrobe')} $dominantColor',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                tr('stats_unused_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (staleItems.isEmpty)
                Text(
                  tr('stats_unused_empty'),
                  style: const TextStyle(color: Colors.grey),
                )
              else
                Column(
                  children: staleItems.map((entry) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.hourglass_bottom, color: Color(0xFFB185A7)),
                        title: Text(entry.name),
                        subtitle: Text(entry.type),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StaleEntry {
  final String name;
  final String type;

  _StaleEntry({required this.name, required this.type});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _WarningCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}