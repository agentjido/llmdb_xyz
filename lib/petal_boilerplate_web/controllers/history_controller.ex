defmodule PetalBoilerplateWeb.HistoryController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplate.Catalog

  @default_model_limit 200
  @default_recent_limit 50

  plug :put_noindex_header

  def model(conn, %{"provider" => provider, "id" => id_parts} = params) do
    model_id = join_model_id(id_parts)
    model_key = "#{provider}:#{model_id}"
    limit = Map.get(params, "limit", @default_model_limit)
    history = history_module()

    with {:ok, events} <- history.timeline(provider, model_id, limit),
         {:ok, meta} <- history.meta() do
      if events == [] and is_nil(Catalog.find_model(provider, model_id)) do
        conn
        |> put_status(:not_found)
        |> json(%{error: "model_not_found", model_key: model_key})
      else
        json(conn, %{
          schema_version: schema_version(events),
          model_key: model_key,
          events: events,
          meta: meta
        })
      end
    else
      {:error, :invalid_limit} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "invalid_limit"})

      {:error, :history_unavailable} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "history_unavailable"})

      {:error, _reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "history_unavailable"})
    end
  end

  def recent(conn, params) do
    limit = Map.get(params, "limit", @default_recent_limit)
    history = history_module()

    with {:ok, events} <- history.recent(limit),
         {:ok, meta} <- history.meta() do
      json(conn, %{
        schema_version: schema_version(events),
        recent: true,
        events: events,
        meta: meta
      })
    else
      {:error, :invalid_limit} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "invalid_limit"})

      {:error, :history_unavailable} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "history_unavailable"})

      {:error, _reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "history_unavailable"})
    end
  end

  defp join_model_id(parts) when is_list(parts), do: Enum.join(parts, "/")
  defp join_model_id(part) when is_binary(part), do: part

  defp schema_version([]), do: 1

  defp schema_version([event | _]) do
    map_get(event, "schema_version", :schema_version) || 1
  end

  defp map_get(map, string_key, atom_key) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end

  defp put_noindex_header(conn, _opts) do
    put_resp_header(conn, "x-robots-tag", "noindex")
  end
end
