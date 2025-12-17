defmodule PetalBoilerplateWeb.MCPController do
  use PetalBoilerplateWeb, :controller

  def handle(conn, %{"method" => "tools/list"}) do
    tools = [
      %{
        name: "query_models",
        description:
          "Search and filter LLM models by capabilities, provider, cost, and other criteria",
        inputSchema: %{
          type: "object",
          properties: %{
            provider: %{
              type: "string",
              description: "Filter by provider (openai, anthropic, google, etc)"
            },
            capabilities: %{
              type: "object",
              properties: %{
                chat: %{type: "boolean"},
                embeddings: %{type: "boolean"},
                reasoning: %{type: "boolean"},
                tools: %{type: "boolean"},
                vision: %{type: "boolean"}
              }
            },
            max_cost_input: %{
              type: "number",
              description: "Maximum input cost per million tokens"
            },
            max_cost_output: %{
              type: "number",
              description: "Maximum output cost per million tokens"
            },
            min_context: %{type: "integer", description: "Minimum context window size"},
            limit: %{type: "integer", description: "Maximum number of results to return"}
          }
        }
      },
      %{
        name: "get_model",
        description:
          "Get detailed information about a specific model by spec (provider:model_id)",
        inputSchema: %{
          type: "object",
          properties: %{
            spec: %{
              type: "string",
              description: "Model spec in format 'provider:model_id' (e.g. 'openai:gpt-4o')"
            }
          },
          required: ["spec"]
        }
      },
      %{
        name: "list_providers",
        description: "Get list of all LLM providers",
        inputSchema: %{type: "object", properties: %{}}
      }
    ]

    json(conn, %{tools: tools})
  end

  def handle(conn, %{
        "method" => "tools/call",
        "params" => %{"name" => "query_models", "arguments" => args}
      }) do
    all_models = LLMDB.models()

    filtered =
      all_models
      |> filter_by_provider(args["provider"])
      |> filter_by_capabilities(args["capabilities"])
      |> filter_by_cost(args["max_cost_input"], args["max_cost_output"])
      |> filter_by_context(args["min_context"])
      |> limit_results(args["limit"])

    results =
      Enum.map(filtered, fn model ->
        %{
          spec: "#{model.provider}:#{model.id}",
          name: model.name,
          provider: model.provider,
          family: model.family,
          capabilities: serialize_capabilities(model.capabilities),
          cost: model.cost,
          limits: model.limits,
          modalities: model.modalities
        }
      end)

    json(conn, %{content: [%{type: "text", text: Jason.encode!(results, pretty: true)}]})
  end

  def handle(conn, %{
        "method" => "tools/call",
        "params" => %{"name" => "get_model", "arguments" => %{"spec" => spec}}
      }) do
    case LLMDB.model(spec) do
      {:ok, model} ->
        result = %{
          spec: "#{model.provider}:#{model.id}",
          id: model.id,
          name: model.name,
          provider: model.provider,
          family: model.family,
          aliases: model.aliases,
          tags: model.tags,
          capabilities: serialize_capabilities(model.capabilities),
          cost: model.cost,
          limits: model.limits,
          modalities: model.modalities,
          deprecated: model.deprecated
        }

        json(conn, %{content: [%{type: "text", text: Jason.encode!(result, pretty: true)}]})

      {:error, _} ->
        json(conn, %{content: [%{type: "text", text: "Model not found: #{spec}"}], isError: true})
    end
  end

  def handle(conn, %{"method" => "tools/call", "params" => %{"name" => "list_providers"}}) do
    providers =
      LLMDB.providers()
      |> Enum.map(fn provider ->
        %{
          id: provider.id,
          name: provider.name,
          base_url: provider.base_url,
          model_count: length(LLMDB.models(provider.id))
        }
      end)

    json(conn, %{content: [%{type: "text", text: Jason.encode!(providers, pretty: true)}]})
  end

  def handle(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{error: "Unknown method or invalid request"})
  end

  defp filter_by_provider(models, nil), do: models

  defp filter_by_provider(models, provider) when is_binary(provider) do
    provider_atom = String.to_existing_atom(provider)
    Enum.filter(models, fn model -> model.provider == provider_atom end)
  rescue
    ArgumentError -> models
  end

  defp filter_by_capabilities(models, nil), do: models

  defp filter_by_capabilities(models, caps) when is_map(caps) do
    Enum.filter(models, fn model ->
      model_caps = model.capabilities || %{}

      Enum.all?(caps, fn {key, required} ->
        key_atom = if is_binary(key), do: String.to_existing_atom(key), else: key

        cond do
          not required -> true
          key_atom == :chat -> Map.get(model_caps, :chat) == true
          key_atom == :embeddings -> Map.get(model_caps, :embeddings) == true
          key_atom == :reasoning -> get_in(model_caps, [:reasoning, :enabled]) == true
          key_atom == :tools -> get_in(model_caps, [:tools, :enabled]) == true
          key_atom == :vision -> :image in (get_in(model_caps, [:modalities, :input]) || [])
          true -> false
        end
      end)
    end)
  rescue
    ArgumentError -> models
  end

  defp filter_by_cost(models, max_in, max_out) do
    models
    |> filter_by_cost_input(max_in)
    |> filter_by_cost_output(max_out)
  end

  defp filter_by_cost_input(models, nil), do: models

  defp filter_by_cost_input(models, max_cost) when is_number(max_cost) do
    Enum.filter(models, fn model ->
      case get_in(model.cost, [:input]) do
        cost when is_number(cost) -> cost <= max_cost
        _ -> false
      end
    end)
  end

  defp filter_by_cost_output(models, nil), do: models

  defp filter_by_cost_output(models, max_cost) when is_number(max_cost) do
    Enum.filter(models, fn model ->
      case get_in(model.cost, [:output]) do
        cost when is_number(cost) -> cost <= max_cost
        _ -> false
      end
    end)
  end

  defp filter_by_context(models, nil), do: models

  defp filter_by_context(models, min_context) when is_integer(min_context) do
    Enum.filter(models, fn model ->
      case get_in(model.limits, [:context]) do
        context when is_integer(context) -> context >= min_context
        _ -> false
      end
    end)
  end

  defp limit_results(models, nil), do: models

  defp limit_results(models, limit) when is_integer(limit) and limit > 0 do
    Enum.take(models, limit)
  end

  defp limit_results(models, _), do: models

  defp serialize_capabilities(nil), do: %{}

  defp serialize_capabilities(caps) do
    %{
      chat: Map.get(caps, :chat, false),
      embeddings: Map.get(caps, :embeddings, false),
      reasoning: get_in(caps, [:reasoning, :enabled]) || false,
      tools: get_in(caps, [:tools, :enabled]) || false,
      tools_streaming: get_in(caps, [:tools, :streaming]) || false,
      json_native: get_in(caps, [:json, :native]) || false,
      streaming_text: get_in(caps, [:streaming, :text]) || false
    }
  end
end
