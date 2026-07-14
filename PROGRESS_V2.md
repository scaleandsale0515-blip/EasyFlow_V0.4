# EasyFlow V2 — Update Tracker (screenshot review round)

Base: confirmed-building zip (EasyFlow_V0.1-main, post Codemagic fix).
Working copy: /home/claude/easyflow_v2

## Plan (check off as completed)
- [ ] 1. AppSettings model: add isActivated, isDarkMode, 4x chart-visibility bools
- [ ] 2. TransportEntry model: add locationName, clientName, cementBagsDispatched, cementReduceFromStock
- [x] 3. Light theme (AppTheme.light) + keep Dark as-is + ThemeService (live, persisted)
      — CRITICAL FIX: converting AppColors from consts to theme-aware getters
      broke every `const` expression referencing AppColors.* across 23 files
      (getters aren't compile-time constants). Fixed by stripping const from
      every affected widget construction (both same-line and multi-line
      spans, verified with proper paren-depth tracking, not just regex).
- [x] 4. One-time activation: Lock Screen skipped after first successful unlock; real app icon on Lock Screen
- [x] 5. Production entry: highlight Cement Bags Used field
- [x] 6. Transport entry: add Location + Client Name fields; move Cement out of item rows into own highlighted block (legacy isCement rows still read for backward-compat data)
- [x] 7. StockService: read cement-dispatched from new TransportEntry field (+ legacy row fallback)
- [x] 8. Production/Transport list: segmented By Date/By Worker(Transporter) toggle + toast
- [x] 9. Production/Transport list: card redesign (fix ListTile squeeze bug), responsive, Transport card shows Location/Client
- [x] 10. Dashboard: Inventory stock number emphasis
- [x] 11. Dashboard: Cement Stock section header + highlighted cards
- [x] 12. Dashboard: tappable Today's Summary sheet rows + Recent Activity cards -> push entry screens
- [x] 13. Dashboard: instant live refresh (Listenable.merge across all relevant boxes) — also wired chart-visibility settings in while rewriting (item 15's Dashboard-side half)
- [x] 14. Worker/Transporter list: same live-listening check (both fixed with Listenable.merge; Ledger screens were already fine since they refresh naturally on navigation return)
- [x] 15. Settings screen (new): theme toggle, 4 chart toggles w/ toast, T&C link
- [x] 16. More menu: remove T&C row, add Settings row
- [x] 17. main.dart: wire activation check + ThemeService into MaterialApp (done as part of item 4)
- [x] 18. Final: full re-audit (brace/paren balance, import resolution, adapter field-count check), repackage zip

## Final audit results (all passed)
- Brace/paren balance: clean across every file
- Every relative import resolves to a real file
- AppSettings adapter: 13 model fields = writeByte(13) ✓
- TransportEntry adapter: 13 model fields = writeByte(13) ✓ (TransportItemRow: 5 = writeByte(5) ✓)
- All 14 Hive typeIds still unique, no gaps, all registered
- Zero remaining `const` + `AppColors` conflicts (same-line and multi-line both re-swept after all new code was added)
- android/ folder confirmed byte-for-byte untouched (diff against the confirmed-building base) - nothing there was changed
- No leftover legacy cement-row UI construction in Transport entry (isCement always false for new rows; old rows still read correctly for backward compatibility)

## Backward compatibility notes for existing test data
- Old AppSettings records (7 fields) load fine - new fields (isActivated, isDarkMode, 4 chart toggles) default sensibly (isActivated=false so it'll ask to unlock once more after this update, isDarkMode=true, all charts=true)
- Old TransportEntry records (9 fields) load fine - locationName/clientName default to null (card just won't show that row), cementBagsDispatched defaults to 0, cementReduceFromStock defaults to true
- Old Transport entries that used the legacy isCement item-row pattern still count correctly in StockService's cement math (fallback loop kept)
