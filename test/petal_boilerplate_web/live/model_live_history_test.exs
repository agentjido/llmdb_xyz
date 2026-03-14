defmodule PetalBoilerplateWeb.ModelLiveHistoryTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

  defmodule HistoryTimelineStub do
    def available?, do: true

    def meta do
      {:ok,
       %{
         "from_snapshot_id" => "1111111111111111111111111111111111111111111111111111111111111111",
         "to_snapshot_id" => "2222222222222222222222222222222222222222222222222222222222222222",
         "from_ref" => "1111111111111111111111111111111111111111111111111111111111111111",
         "to_ref" => "2222222222222222222222222222222222222222222222222222222222222222",
         "range_kind" => "snapshots",
         "generated_at" => "2026-02-27T00:00:00Z"
       }}
    end

    def timeline(_provider, _model_id, _limit) do
      {:ok,
       [
         %{
           "schema_version" => 1,
           "type" => "changed",
           "captured_at" => "2026-02-20T12:00:00Z",
           "changes" => [
             %{"path" => "limits.context"},
             %{"path" => "cost.input"},
             %{"path" => "cost.output"},
             %{"path" => "modalities.input"}
           ]
         }
       ]}
    end

    def recent(_limit), do: {:ok, []}
  end

  defmodule HistoryUnavailableStub do
    def available?, do: false
    def meta, do: {:error, :history_unavailable}
    def timeline(_provider, _model_id, _limit), do: {:error, :history_unavailable}
    def recent(_limit), do: {:error, :history_unavailable}
  end

  setup do
    original_history_module = Application.get_env(:petal_boilerplate, :history_module)

    on_exit(fn ->
      if original_history_module do
        Application.put_env(:petal_boilerplate, :history_module, original_history_module)
      else
        Application.delete_env(:petal_boilerplate, :history_module)
      end
    end)

    :ok
  end

  test "model detail renders timeline and raw API link", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryTimelineStub)

    model = Catalog.list_all_models() |> List.first()
    show_path = model_show_path(model)
    raw_api_path = model_api_path(model)

    {:ok, _view, html} = live(conn, show_path)

    assert html =~ "History"
    assert html =~ "changed"
    assert html =~ "limits.context"
    assert html =~ raw_api_path
  end

  test "model detail renders graceful fallback when history is unavailable", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryUnavailableStub)

    model = Catalog.list_all_models() |> List.first()
    show_path = model_show_path(model)

    {:ok, _view, html} = live(conn, show_path)

    assert html =~ "History not available for this deployment."
  end

  defp model_show_path(model) do
    provider = URI.encode(to_string(model.provider))
    model_id = encode_model_id(model.model_id)
    "/models/#{provider}/#{model_id}"
  end

  defp model_api_path(model) do
    provider = URI.encode(to_string(model.provider))
    model_id = encode_model_id(model.model_id)
    "/api/history/#{provider}/#{model_id}?limit=200"
  end

  defp encode_model_id(model_id) do
    model_id
    |> String.split("/")
    |> Enum.map(&URI.encode/1)
    |> Enum.join("/")
  end
end
