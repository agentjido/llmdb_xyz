# AGENTS.md

## Commands

### Build & Run
- **Dev server**: `mix phx.server` (or `iex -S mix phx.server` for interactive)
- **Setup**: `mix setup` (deps, DB, assets)
- **Assets**: `mix assets.build` (Tailwind + esbuild)

### Testing
- **All tests**: `mix test`
- **Single test file**: `mix test path/to/test_file.exs`
- **Single test**: `mix test path/to/test_file.exs:123` (with line number)
- **Watch mode**: `mix test.watch` (requires inotify-tools or similar)

### Code Quality
- **Format**: `mix format`
- **Check format**: `mix format --check-formatted`

### Database
- **Create**: `mix ecto.create`
- **Migrate**: `mix ecto.migrate`
- **Reset**: `mix ecto.reset` (drop + create + migrate + seed)

## Architecture

**Type**: Phoenix 1.7 LiveView web app showcasing the `llm_db` Elixir package.

**Key modules**:
- `PetalBoilerplate.Catalog` - Domain logic: model filtering, sorting, pagination, ETS caching
- `PetalBoilerplate.Application` - OTP supervision tree
- `PetalBoilerplateWeb.Router` - Routes: `/` (model list), `/models/:provider/:id` (detail), `/about`, `/api/mcp` (POST)
- `PetalBoilerplateWeb.Live.ModelLive` - Phoenix LiveView component for browsing/filtering models
- `PetalBoilerplateWeb.Components.*` - Reusable UI components (Petal Components framework)

**Data flow**: `LLMDB` module → `Catalog.list_all_models()` (with ETS cache) → `ModelLive` (filtering/sorting/pagination) → HTML/Heex templates

**Storage**: No database (pure LLM model catalog data from `llm_db` package).

## Code Style

**Language**: Elixir 1.14+

**Formatting**: Phoenix conventions (via `.formatter.exs`):
- Module exports in `uses/1` and documentation
- Route macros without parens: `get "/path", MyController, :action`
- Slots/attrs without parens in components
- 2-space indentation, trailing commas in multi-line lists

**Imports**:
- `alias ModuleName` for references; `import` rarely used
- Qualified calls preferred: `Enum.map()` over `import Enum`

**Naming**:
- Modules: PascalCase; functions: snake_case
- Private functions: `defp` prefix with `_` for internal helpers
- Test modules: `*Test` suffix in `test/` directory

**Error handling**:
- Functions return `{:ok, data}` / `{:error, reason}` or raise on exceptional failures
- LiveView uses `handle_info` for async updates
- Catalog functions don't validate; assume llm_db data is valid

**Types & Patterns**:
- Use maps for flexible data structures (filters, params)
- MapSet for fast membership tests (provider IDs, modalities, capabilities)
- Pattern matching preferred in function heads (not guards when avoidable)

**Special notes**:
- Atom exhaustion: providers/modalities use strings not atoms (see `parse_provider_ids`)
- ETS caching: Catalog pre-enriches models (search indexes, capability sets) into `:catalog_models` table
- LiveView lifecycle: use `mount/3`, `handle_event/3`, `handle_info/2` patterns
