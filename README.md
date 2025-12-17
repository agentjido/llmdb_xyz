# llmdb.xyz

LLM Model Database - A showcase for the [llm_db](https://github.com/agentjido/llm_db) Elixir package.

Browse and compare LLM models with capability-aware filtering.

## Features

- Browse models from all major LLM providers (OpenAI, Anthropic, Google, Mistral, and more)
- Filter by capabilities (chat, tools, JSON, streaming, reasoning, embeddings)
- Filter by input modalities (text, image, audio)
- Filter by context window, output limits, and pricing
- Sort by any column
- Mobile-friendly card view
- Dark mode support

## Powered by llm_db

This site is powered by [llm_db](https://hex.pm/packages/llm_db), an Elixir package providing LLM model metadata with fast, capability-aware lookups.

Add it to your project:

```elixir
def deps do
  [
    {:llm_db, "~> 2025.12.1"}
  ]
end
```

### Example Usage

```elixir
# List all providers
LLMDb.provider()

# List all models
LLMDb.model()

# Find models with specific capabilities
LLMDb.model()
|> Enum.filter(fn model ->
  caps = model.capabilities || %{}
  caps[:chat] and get_in(caps, [:tools, :enabled])
end)
```

## Development

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+

### Setup

```bash
# Install dependencies
mix deps.get

# Build assets
mix assets.build

# Start the server
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000) to see the app.

### Running in IEx

```bash
iex -S mix phx.server
```

## Deployment

The application is configured for deployment to standard Phoenix hosting platforms.

### Environment Variables

- `SECRET_KEY_BASE` - Required for production
- `HOST` - The hostname (default: llmdb.xyz)
- `PORT` - The port to listen on (default: 4000)
- `ENABLE_ANALYTICS` - Set to "true" to enable Plausible analytics

## License

MIT
