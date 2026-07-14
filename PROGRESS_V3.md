# EasyFlow V3 — Update Tracker (round 3: backup safety, theme refresh, collapsible headers)

Base: /home/claude/easyflow_v2 (already has all V2 updates applied and audited).
Working copy: /home/claude/easyflow_v2 (continuing in place, same folder)

## Plan
- [x] 1. Split AppSettings (device-level) from new BusinessSettings (typeId 14, portable) - includes one-time migration of existing opening stock/threshold values so nothing resets
- [x] 2. Redirect all reads/writes of opening stock + threshold to BusinessSettings (StockService, PurchaseListScreen threshold editor; OpeningStockDialog already routed through StockService)
- [x] 3. BackupService: exclude app_settings.hive from backup creation AND from
       restore-write (skip even if present in older zips, for backward compat)
       — this is what actually fixes "restore resets activation/login"
- [x] 4. Restore safety warning dialog (Option A): "Backup Current Data First" /
       "Continue Without Backup" / "Cancel" before any restore proceeds
- [x] 5. Fix theme-toggle instant refresh: remove const from HomeShell() in
       main.dart + _screens list AND individual screen widgets in
       home_shell.dart (the list being fresh alone wasn't enough - the
       individual const widget instances inside it were still canonicalized
       singletons; both needed fixing). Preserves navigation state/scroll
       position since Flutter matches by runtimeType not instance identity.
- [x] 6. Production & Transport list screens: move By Date/Worker(Transporter)
       toggle into AppBar actions (top-right), compact SegmentedButton sized
       to fit
- [x] 7. Production & Transport list screens: YouTube-style collapsible
       Search+Filter header (CustomScrollView + two SliverAppBars - first
       pinned for title+toggle, second floating+snap for search/filter),
       title bar stays pinned, entry list gets full space
- [x] 8. Final full re-audit (brace/paren, imports, adapter field-counts,
       const/AppColors sweep, typeId uniqueness), repackage zip

## Final audit results (all passed)
- Brace/paren balance: clean across every file
- Every relative import resolves to a real file
- BusinessSettings adapter: 3 model fields = writeByte(3) ✓
- All 15 Hive typeIds (0-14) unique, no gaps, all registered
- Zero remaining const+AppColors conflicts (same-line and multi-line, re-swept after all this round's new code)
- android/ folder confirmed still byte-for-byte untouched
- No lingering references to the old combined AppSettings-based opening-stock/threshold pattern anywhere

## What changed this round, in plain terms
1. Backup/Restore can no longer reset your login - device settings (login,
   activation, theme, chart toggles) now live completely separately from
   business data, with a one-time automatic migration so existing opening
   stock/threshold values aren't lost
2. Restore now warns first and offers to safely back up your current data
   before replacing it
3. Precisely fixed why the app needed a restart to show theme changes on
   already-open screens (two `const` widget-caching spots were silently
   telling Flutter "never rebuild this") - fixed without any navigation
   reset or full-app-rebuild side effect
4. Production & Transport screens: toggle moved to top-right of the title
   bar; Search+Filter now collapse out of the way on scroll down and
   snap back on scroll up, exactly like YouTube, giving the entry list
   far more visible space

