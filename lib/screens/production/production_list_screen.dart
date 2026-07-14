import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/production.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'production_entry_screen.dart';

enum _GroupMode { byDate, byWorker }

class ProductionListScreen extends StatefulWidget {
  const ProductionListScreen({super.key});

  @override
  State<ProductionListScreen> createState() => _ProductionListScreenState();
}

class _ProductionListScreenState extends State<ProductionListScreen> {
  _GroupMode _mode = _GroupMode.byDate;
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);
  String _query = '';

  String _workerName(String id) {
    final box = Hive.box<Worker>(HiveBoxes.workers);
    try {
      return box.values.firstWhere((w) => w.id == id).name;
    } catch (_) {
      return '(deleted worker)';
    }
  }

  String _itemLabel(ProductionItemRow row) {
    try {
      final sub = ItemCatalogService.subcategories.values.firstWhere((s) => s.id == row.subcategoryId);
      final cat = ItemCatalogService.categories.values.firstWhere((c) => c.id == row.categoryId);
      return '${cat.name} - ${sub.name}, ${Fmt.qty(row.quantity)} ${row.unit}';
    } catch (_) {
      return 'Item, ${Fmt.qty(row.quantity)}';
    }
  }

  void _setMode(_GroupMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    final label = mode == _GroupMode.byDate ? 'Date' : 'Worker';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Now showing list by $label'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _delete(ProductionEntry e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) await e.delete();
    setState(() {});
  }

  /// Compact segmented toggle sized to fit in an AppBar's actions area.
  Widget _toggle() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SegmentedButton<_GroupMode>(
        style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        segments: const [
          ButtonSegment(value: _GroupMode.byDate, icon: Icon(Icons.calendar_today_outlined, size: 14), label: Text('Date', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: _GroupMode.byWorker, icon: Icon(Icons.person_outline, size: 14), label: Text('Worker', style: TextStyle(fontSize: 12))),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => _setMode(s.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ProductionEntry>(HiveBoxes.production).listenable(),
        builder: (context, Box<ProductionEntry> box, _) {
          final range = _range;
          var entries = box.values.where((e) => range.contains(e.date)).toList();
          if (_query.isNotEmpty) {
            entries = entries.where((e) {
              final worker = _workerName(e.workerId).toLowerCase();
              return worker.contains(_query.toLowerCase());
            }).toList();
          }
          entries.sort((a, b) => b.date.compareTo(a.date));

          return CustomScrollView(
            slivers: [
              // Title bar - stays pinned/visible at all times.
              SliverAppBar(
                title: const Text('Production'),
                pinned: true,
                actions: [_toggle()],
              ),
              // Search + Date filter - floats away on scroll down, snaps
              // back into view the moment the user scrolls up even slightly
              // (same behavior as YouTube's search bar).
              SliverAppBar(
                pinned: false,
                floating: true,
                snap: true,
                toolbarHeight: 118,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.bgDark,
                elevation: 0,
                flexibleSpace: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      SearchBarWidget(hint: 'Search worker...', onChanged: (v) => setState(() => _query = v)),
                      const SizedBox(height: 10),
                      DateFilterBar(onRangeChanged: (r) => setState(() => _range = r)),
                    ],
                  ),
                ),
              ),
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: const EmptyState(icon: Icons.precision_manufacturing_outlined, message: 'No production entries in this period.'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverToBoxAdapter(
                    child: _mode == _GroupMode.byDate ? _buildByDate(entries) : _buildByWorker(entries),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductionEntryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildByDate(List<ProductionEntry> entries) {
    final Map<String, List<ProductionEntry>> grouped = {};
    for (final e in entries) {
      final key = Fmt.dayHeader(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((g) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(g.key, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
            ),
            ...g.value.map((e) => _entryCard(e, showWorker: true)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildByWorker(List<ProductionEntry> entries) {
    final Map<String, List<ProductionEntry>> grouped = {};
    for (final e in entries) {
      final key = _workerName(e.workerId);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((g) {
        final total = g.value.fold(0.0, (sum, e) => sum + e.totalAmount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(g.key, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                  Text(Fmt.money(total), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            ...g.value.map((e) => _entryCard(e, showWorker: false)),
          ],
        );
      }).toList(),
    );
  }

  /// Fully custom Column/Row layout (not a ListTile) - this is the fix for
  /// the letter-wrap bug: no unconstrained trailing widget can ever squeeze
  /// the name down to nothing, since every text element uses Expanded/
  /// Flexible and gets its own row instead of competing for space.
  Widget _entryCard(ProductionEntry e, {required bool showWorker}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductionEntryScreen(existing: e))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: name/date (flexible, never squeezed) + amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      showWorker ? _workerName(e.workerId) : Fmt.dateShort(e.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(Fmt.money(e.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                ],
              ),
              const SizedBox(height: 6),
              // Row 2: items produced, wraps up to 2 lines
              Text(
                e.items.map(_itemLabel).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              // Row 3 (footer): cement chip (left) + edit/delete (right), own dedicated row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (e.cementBagsUsed > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Cement: ${Fmt.qty(e.cementBagsUsed)} bags',
                          style: TextStyle(color: AppColors.warningAmber, fontSize: 11, fontWeight: FontWeight.w600)),
                    )
                  else
                    const SizedBox(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductionEntryScreen(existing: e))),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.delete_outline, size: 18, color: AppColors.balanceRed),
                        onPressed: () => _delete(e),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
