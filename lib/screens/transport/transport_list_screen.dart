import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/transport.dart';
import '../../models/transporter.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'transport_entry_screen.dart';

enum _GroupMode { byDate, byTransporter }

class TransportListScreen extends StatefulWidget {
  const TransportListScreen({super.key});

  @override
  State<TransportListScreen> createState() => _TransportListScreenState();
}

class _TransportListScreenState extends State<TransportListScreen> {
  _GroupMode _mode = _GroupMode.byDate;
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);
  String _query = '';

  String _transporterName(String id) {
    try {
      return Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == id).name;
    } catch (_) {
      return '(deleted transporter)';
    }
  }

  String _rowLabel(TransportItemRow r) {
    try {
      final sub = ItemCatalogService.subcategories.values.firstWhere((s) => s.id == r.subcategoryId);
      return '${sub.name} (${Fmt.qty(r.quantity)})';
    } catch (_) {
      return 'Item (${Fmt.qty(r.quantity)})';
    }
  }

  void _setMode(_GroupMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    final label = mode == _GroupMode.byDate ? 'Date' : 'Transporter';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Now showing list by $label'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _delete(TransportEntry e) async {
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
          ButtonSegment(value: _GroupMode.byTransporter, icon: Icon(Icons.local_shipping_outlined, size: 14), label: Text('Transp.', style: TextStyle(fontSize: 12))),
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
        valueListenable: Hive.box<TransportEntry>(HiveBoxes.transport).listenable(),
        builder: (context, Box<TransportEntry> box, _) {
          final range = _range;
          var entries = box.values.where((e) => range.contains(e.date)).toList();
          if (_query.isNotEmpty) {
            entries = entries.where((e) => _transporterName(e.transporterId).toLowerCase().contains(_query.toLowerCase())).toList();
          }
          entries.sort((a, b) => b.date.compareTo(a.date));

          return CustomScrollView(
            slivers: [
              // Title bar - stays pinned/visible at all times.
              SliverAppBar(
                title: const Text('Transport'),
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
                      SearchBarWidget(hint: 'Search transporter...', onChanged: (v) => setState(() => _query = v)),
                      const SizedBox(height: 10),
                      DateFilterBar(onRangeChanged: (r) => setState(() => _range = r)),
                    ],
                  ),
                ),
              ),
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: const EmptyState(icon: Icons.local_shipping_outlined, message: 'No transport entries in this period.'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverToBoxAdapter(
                    child: _mode == _GroupMode.byDate ? _buildByDate(entries) : _buildByTransporter(entries),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportEntryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildByDate(List<TransportEntry> entries) {
    final Map<String, List<TransportEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(Fmt.dayHeader(e.date), () => []).add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((g) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(g.key, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan))),
            ...g.value.map((e) => _entryCard(e, showTransporter: true)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildByTransporter(List<TransportEntry> entries) {
    final Map<String, List<TransportEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(_transporterName(e.transporterId), () => []).add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((g) {
        final total = g.value.fold(0.0, (sum, e) => sum + e.transportCharge);
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
            ...g.value.map((e) => _entryCard(e, showTransporter: false)),
          ],
        );
      }).toList(),
    );
  }

  /// Fully custom Column/Row layout (not a ListTile) - same fix as
  /// Production's card. Location/Client Name row only renders if at least
  /// one of the two has a value, so entries without them don't show an
  /// empty-looking gap.
  Widget _entryCard(TransportEntry e, {required bool showTransporter}) {
    final hasLocationOrClient = (e.locationName?.isNotEmpty ?? false) || (e.clientName?.isNotEmpty ?? false);
    final itemsSummary = [
      ...e.items.where((r) => !r.isCement).map(_rowLabel),
      if (e.cementBagsDispatched > 0) 'Cement Bags (${Fmt.qty(e.cementBagsDispatched)})',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransportEntryScreen(existing: e))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: name/date (flexible) + trip charge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      showTransporter ? _transporterName(e.transporterId) : Fmt.dateShort(e.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(Fmt.money(e.transportCharge), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                ],
              ),
              const SizedBox(height: 4),
              // Row 2: vehicle type + number
              if (e.vehicleType.isNotEmpty || e.vehicleNo.isNotEmpty)
                Text('${e.vehicleType} ${e.vehicleNo}'.trim(), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              // Row 3: Location + Client Name (only if at least one present)
              if (hasLocationOrClient) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [if (e.locationName?.isNotEmpty ?? false) e.locationName!, if (e.clientName?.isNotEmpty ?? false) e.clientName!].join(' · '),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              // Row 4: items/cement summary
              if (itemsSummary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(itemsSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
              const SizedBox(height: 8),
              // Footer row: edit/delete
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransportEntryScreen(existing: e))),
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
        ),
      ),
    );
  }
}
