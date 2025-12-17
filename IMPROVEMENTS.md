# llmdb.xyz Improvement Plan

## Completed Improvements

### ✅ Phase 1: Critical Fixes & Cleanup

1. **Updated llm_db to latest Hex release**
   - Changed from `{:llm_db, github: "agentjido/llm_db"}` to `{:llm_db, "~> 2025.12.1"}`
   - Updated API calls to use `LLMDB` module (was `LLMDb`)
   - Fixed function names: `providers/0`, `models/0` (plural)

2. **Wired up filters sidebar as collapsible panel**
   - Added global search bar at the top
   - Filters panel is collapsible (toggle button with filter icon)
   - Active filter count badge on the toggle button
   - Responsive grid layout for filter controls
   - Shows "Showing X models" count

3. **Fixed integer number formatting bug**
   - Changed from broken `Enum.chunk_every/2` + `Enum.join/2` to regex replacement
   - Now correctly formats integers with thousand separators

4. **Updated root layout branding**
   - Changed title suffix from "Phoenix Framework" to "llmdb.xyz"
   - Updated default title from "PetalBoilerplate" to "LLM Model Database"
   - Updated Twitter card title

5. **Updated README.md**
   - Complete rewrite with llmdb.xyz-specific content
   - Features list, development setup, llm_db usage examples

6. **Cleaned unused dependencies**
   - Removed `phoenix_ecto`, `ecto_sql`, `postgrex`
   - Removed `lib/petal_boilerplate/repo.ex`

### ✅ Phase 2: Architecture Improvements

7. **Extracted Catalog context module**
   - Created `lib/petal_boilerplate/catalog.ex`
   - Moved all domain logic: filtering, sorting, enrichment
   - Public API: `list_providers/0`, `list_all_models/0`, `list_models/3`, `parse_filters/1`
   - Formatting helpers: `format_number/1`, `format_cost/1`
   - `default_filters/0`, `default_sort/0`, `active_filter_count/1`

8. **DRY capability computation**
   - Created `@capability_definitions` module attribute
   - Single source of truth for capability keys, paths, and labels
   - Used in both enrichment (`enrich_model/1`) and UI (`capability_badges/1`)
   - `labeled_capabilities/0` returns only capabilities with UI labels

9. **Hardened filter parsing**
   - Provider IDs now stored as strings (not atoms) to avoid atom exhaustion
   - Added `__provider_str` to enriched models for string comparison
   - Modalities still use atoms (limited set, already existing)

### ✅ Phase 3: Performance Optimization

10. **ETS caching for enriched models**
    - Added `init_cache/0` to pre-warm enriched models in ETS on app startup
    - `list_all_models/0` now reads from ETS cache instead of re-enriching on every mount
    - Cache is initialized once at application startup in `application.ex`

11. **Pagination support**
    - Added `paginate/3` function with default page size of 50 models
    - Returns `{page_models, total, total_pages, current_page}`
    - Reduces DOM size from 2000+ rows to 50 at a time

12. **LiveView streams for efficient DOM updates**
    - Converted model list to use `stream/4` instead of assigns
    - Table and cards now use `phx-update="stream"` for incremental DOM patching
    - Added unique `id` field to enriched models for stream tracking

13. **Pagination UI**
    - Added Prev/Next buttons at top and bottom of model list
    - Shows "Page X of Y" counter
    - Buttons disabled at list boundaries

---

## Pending Improvements

### New Features (Next Phase)

- [x] **Model detail page** (`/models/:provider/:id`) - Modal opens with shareable URL
- [x] **Landing page hero section** with llm_db description
- [x] **About page** (`/about`) with features and community links
- [ ] **Public JSON API** (`GET /api/models`)

### UI/UX Polish

- [ ] Add "Clear all filters" button
- [x] Add header/footer navigation - About link, Discord icon, GitHub icon, footer credit
- [x] Add tooltips on capability badges

### Cleanup

- [ ] Remove unused `page_live.ex` and `form_live.ex` boilerplate
- [ ] Remove unused routes in router
- [ ] Consider renaming project from PetalBoilerplate to LlmdbXyz

---

## Architecture Summary

```
lib/
├── petal_boilerplate/
│   ├── application.ex      # App startup, LLMDB.load()
│   ├── catalog.ex          # Domain logic (NEW)
│   └── mailer.ex           # Unused
├── petal_boilerplate_web/
│   ├── components/
│   │   ├── model_components.ex  # Table, cards, badges
│   │   └── ...
│   ├── controllers/
│   │   └── mcp_controller.ex    # MCP API endpoint
│   ├── live/
│   │   ├── model_live.ex        # Main LiveView (refactored)
│   │   └── model_live.html.heex # Template with filters
│   └── ...
```

### Key Design Decisions

1. **Catalog as context module**: Separates domain logic from LiveView, enables unit testing
2. **String-based provider filtering**: Avoids atom exhaustion from user input
3. **Centralized capability definitions**: Single source of truth prevents drift between enrichment and UI
4. **Collapsible filters**: Keeps main view clean while allowing advanced filtering
