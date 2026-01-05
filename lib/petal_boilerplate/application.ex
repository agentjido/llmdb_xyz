defmodule PetalBoilerplate.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Initialize LLMDB on startup
    case LLMDB.load() do
      {:ok, _} -> :ok
      {:error, _} -> LLMDB.load_empty()
    end

    # Pre-warm the model cache for fast initial load
    PetalBoilerplate.Catalog.init_cache()

    children = [
      # Start the Telemetry supervisor
      PetalBoilerplateWeb.Telemetry,
      # Start the Ecto repository
      # PetalBoilerplate.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: PetalBoilerplate.PubSub},
      # Start Finch
      {Finch, name: PetalBoilerplate.Finch},
      # Start ChromicPDF for OG image generation
      ChromicPDF,
      # Start OG image cache
      PetalBoilerplate.OGImage,
      # Start the Endpoint (http/https)
      PetalBoilerplateWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PetalBoilerplate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PetalBoilerplateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
