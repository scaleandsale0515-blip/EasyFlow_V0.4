import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/item_catalog.dart';
import '../../models/transport.dart';
import '../../models/transporter.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';

class TransportEntryScreen extends StatefulWidget {
  final TransportEntry? existing;
  const TransportEntryScreen({super.key, this.existing});

  @override
  State<TransportEntryScreen> createState() => _TransportEntryScreenState();
}

/// A dispatched product row. Cement is handled separately now (its own
/// highlighted block below), so rows here are always products.
class _TRowData {
  String? categoryId;
  String? subcategoryId;
  double quantity = 0;
  bool reduceFromStock = true;
  final qtyCtrl = TextEditingController();
}

class _TransportEntryScreenState extends State<TransportEntryScreen> {
  DateTime _date = DateTime.now();
  String? _transporterId;
  final _transporterSearchCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _chargeCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final _cementQtyCtrl = TextEditingController(text: '0');
  bool _cementReduceFromStock = true;
  final List<_TRowData> _rows = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _date = e.date;
      _transporterId = e.transporterId;
      final t = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere(
          (t) => t.id == e.transporterId,
          orElse: () => Transporter(id: '', name: '(deleted transporter)'));
      _transporterSearchCtrl.text = t.name;
      _vehicleTypeCtrl.text = e.vehicleType;
      _vehicleNoCtrl.text = e.vehicleNo;
      _locationCtrl.text = e.locationName ?? '';
      _clientNameCtrl.text = e.clientName ?? '';
      _chargeCtrl.text = e.transportCharge.toString();
      _notesCtrl.text = e.notes ?? '';
      _cementQtyCtrl.text = Fmt.qty(e.cementBagsDispatched);
      _cementReduceFromStock = e.cementReduceFromStock;
      // Product rows only - legacy cement rows (from before this update)
      // are intentionally skipped here since cement now lives in its own
      // field; their historical stock impact is still counted by
      // StockService's legacy fallback, so nothing is lost.
      for (final r in e.items.where((r) => !r.isCement)) {
        final row = _TRowData()
          ..categoryId = r.categoryId
          ..subcategoryId = r.subcategoryId
          ..quantity = r.quantity
          ..reduceFromStock = r.reduceFromStock;
        row.qtyCtrl.text = Fmt.qty(r.quantity);
        _rows.add(row);
      }
      if (_rows.isEmpty) _rows.add(_TRowData());
    } else {
      _rows.add(_TRowData());
    }
  }

  void _pickTransporter() async {
    final transporters = Hive.box<Transporter>(HiveBoxes.transporters).values.where((t) => t.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    String query = '';
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = query.isEmpty
              ? transporters
              : transporters.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SizedBox(
              height: 480,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Search transporter...', prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(filtered[i].name),
                        onTap: () => Navigator.pop(ctx, filtered[i].id),
                      ),
                    ),
                  ),
                  if (query.trim().isNotEmpty && !transporters.any((t) => t.name.toLowerCase() == query.trim().toLowerCase()))
                    ListTile(
                      leading: Icon(Icons.add, color: AppColors.accentCyan),
                      title: Text('Add new transporter "$query"'),
                      onTap: () async {
                        final newT = Transporter(id: newId(), name: query.trim());
                        await Hive.box<Transporter>(HiveBoxes.transporters).add(newT);
                        if (ctx.mounted) Navigator.pop(ctx, newT.id);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      final t = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == result);
      setState(() {
        _transporterId = result;
        _transporterSearchCtrl.text = t.name;
        if (t.lastVehicleType != null) _vehicleTypeCtrl.text = t.lastVehicleType!;
        if (t.lastVehicleNo != null) _vehicleNoCtrl.text = t.lastVehicleNo!;
      });
    }
  }

  Future<void> _save() async {
    if (_transporterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a transporter')));
      return;
    }
    final validRows = _rows.where((r) => r.quantity > 0 && r.subcategoryId != null).toList();
    final cementQty = double.tryParse(_cementQtyCtrl.text.trim()) ?? 0;
    if (validRows.isEmpty && cementQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item or cement quantity')));
      return;
    }
    final items = validRows
        .map((r) => TransportItemRow(
              isCement: false,
              categoryId: r.categoryId,
              subcategoryId: r.subcategoryId,
              quantity: r.quantity,
              reduceFromStock: r.reduceFromStock,
            ))
        .toList();

    // Remember vehicle details against this transporter for next time.
    final transporter = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == _transporterId);
    transporter.lastVehicleType = _vehicleTypeCtrl.text.trim();
    transporter.lastVehicleNo = _vehicleNoCtrl.text.trim();
    await transporter.save();

    final box = Hive.box<TransportEntry>(HiveBoxes.transport);
    if (widget.existing == null) {
      await box.add(TransportEntry(
        id: newId(),
        date: _date,
        transporterId: _transporterId!,
        vehicleType: _vehicleTypeCtrl.text.trim(),
        vehicleNo: _vehicleNoCtrl.text.trim(),
        items: items,
        transportCharge: double.tryParse(_chargeCtrl.text.trim()) ?? 0,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        locationName: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        clientName: _clientNameCtrl.text.trim().isEmpty ? null : _clientNameCtrl.text.trim(),
        cementBagsDispatched: cementQty,
        cementReduceFromStock: _cementReduceFromStock,
      ));
    } else {
      final e = widget.existing!;
      e.date = _date;
      e.transporterId = _transporterId!;
      e.vehicleType = _vehicleTypeCtrl.text.trim();
      e.vehicleNo = _vehicleNoCtrl.text.trim();
      e.items = items;
      e.transportCharge = double.tryParse(_chargeCtrl.text.trim()) ?? 0;
      e.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      e.locationName = _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim();
      e.clientName = _clientNameCtrl.text.trim().isEmpty ? null : _clientNameCtrl.text.trim();
      e.cementBagsDispatched = cementQty;
      e.cementReduceFromStock = _cementReduceFromStock;
      await e.save();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ItemCatalogService.categories.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Transport' : 'Edit Transport')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 20),
            title: Text(Fmt.date(_date)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (picked != null) setState(() => _date = picked);
              },
              child: const Text('Change'),
            ),
          ),
          TextField(
            controller: _transporterSearchCtrl,
            readOnly: true,
            onTap: _pickTransporter,
            decoration: const InputDecoration(labelText: 'Transporter', prefixIcon: Icon(Icons.local_shipping_outlined)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _vehicleTypeCtrl, decoration: const InputDecoration(labelText: 'Vehicle Type'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _vehicleNoCtrl, decoration: const InputDecoration(labelText: 'Vehicle No.'))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 12),
          TextField(controller: _clientNameCtrl, decoration: const InputDecoration(labelText: 'Client Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 16),
          const Text('Dispatch Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final subs = row.categoryId == null ? <ItemSubcategory>[] : ItemCatalogService.subcategoriesFor(row.categoryId!);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: row.categoryId,
                            decoration: const InputDecoration(labelText: 'Category'),
                            isExpanded: true,
                            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() {
                              row.categoryId = v;
                              row.subcategoryId = null;
                            }),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.balanceRed),
                          onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: row.subcategoryId,
                      decoration: const InputDecoration(labelText: 'Subcategory / Size'),
                      isExpanded: true,
                      items: subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: row.categoryId == null ? null : (v) => setState(() => row.subcategoryId = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: row.qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Qty'),
                      onChanged: (v) => row.quantity = double.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Reduce from stock?', style: TextStyle(fontSize: 14)),
                      subtitle: !row.reduceFromStock
                          ? Text('Borrowed / friend factory stock - won\'t affect your stock', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                          : null,
                      value: row.reduceFromStock,
                      onChanged: (v) => setState(() => row.reduceFromStock = v),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _rows.add(_TRowData())),
            icon: const Icon(Icons.add),
            label: const Text('Add another item'),
          ),
          const SizedBox(height: 12),
          // Cement Bags - separated out from Dispatch Items, own highlighted block
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warningAmber.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.warningAmber, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Cement Bags Dispatched', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warningAmber, fontSize: 14)),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _cementQtyCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Reduce from stock?', style: TextStyle(fontSize: 14)),
                  subtitle: !_cementReduceFromStock
                      ? Text('Borrowed / friend factory stock - won\'t affect your stock', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                      : null,
                  value: _cementReduceFromStock,
                  onChanged: (v) => setState(() => _cementReduceFromStock = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _chargeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Transport Charge (₹, flat per trip)'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save Transport Entry'))),
        ],
      ),
    );
  }
}
