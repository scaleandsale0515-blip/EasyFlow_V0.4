# EasyFlow V4 — Update Tracker (round 4: dashboard fixes, reordering)

Base: /home/claude/easyflow_v2 (V2 + V3 already applied and audited).

## Already done earlier in this conversation (before "ALL SET")
- [x] Dashboard live-refresh: added BusinessSettings box to Listenable.merge
      list (fixes Opening Stock / Threshold not updating instantly)
- [x] All 4 charts: theme-aware tooltip color/text via new ChartStyle helper
      (lib/utils/chart_style.dart), Worker Chart's tap-to-select preserved

## This batch
- [x] 1. Dashboard: move "Pending Dues" section to right after "Cement Stock"
       (was at the very bottom, after Recent Activity)
- [x] 2. SectionHeader widget: add optional `subtitle` param (Option A - reusable)
- [x] 3. Dashboard: "Pending Dues" header gets subtitle "(Money to pay and to collect)",
       tight spacing
- [x] 4. More menu: reorder so Transporters comes before Item Catalog
       (Worker -> Transporters -> Item Catalog -> Purchase/Raw Material ->
       Company Profile -> Backup & Restore -> Settings)
- [x] 5. (Company logo on Dashboard - SKIPPED per explicit request, no action)
- [x] 6. Final full re-audit + repackage zip

## Final audit results (all passed)
- Brace/paren balance: clean across every file
- Every relative import resolves to a real file
- Zero remaining const+AppColors conflicts (same-line and multi-line)
- All 15 Hive typeIds still unique, no gaps
- android/ folder confirmed still byte-for-byte untouched

## Dashboard section order now
Welcome -> Alerts -> Inventory -> Today's Summary -> Cement Stock ->
Pending Dues (Money to pay and to collect) -> Charts -> Recent Activity

## More menu order now
Worker -> Transporters -> Item Catalog -> Purchase/Raw Material ->
Company Profile -> Backup & Restore -> Settings
