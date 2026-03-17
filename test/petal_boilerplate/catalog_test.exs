defmodule PetalBoilerplate.CatalogTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.Catalog

  defmodule HistoryStub do
    def available?, do: true
    def meta, do: {:ok, %{}}
    def timeline(_provider, _model_id, _limit), do: {:ok, []}

    def recent(_limit) do
      {:ok, Application.get_env(:petal_boilerplate, :catalog_test_recent_events, [])}
    end
  end

  setup do
    original_history_module = Application.get_env(:petal_boilerplate, :history_module)
    original_recent_events = Application.get_env(:petal_boilerplate, :catalog_test_recent_events)

    Catalog.refresh_cache()

    on_exit(fn ->
      restore_env(:history_module, original_history_module)
      restore_env(:catalog_test_recent_events, original_recent_events)
      Catalog.refresh_cache()
    end)

    :ok
  end

  test "list_all_models backfills history metadata for a stale cache" do
    [target_model | _] = Catalog.list_all_models() |> Enum.take(3)

    captured_at =
      DateTime.utc_now()
      |> DateTime.add(-2 * 86_400, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    stale_models =
      Catalog.list_all_models()
      |> Enum.take(3)
      |> Enum.map(fn model ->
        model
        |> Map.put(:__last_changed_at, nil)
        |> Map.put(:__last_changed_epoch, nil)
      end)

    Application.put_env(:petal_boilerplate, :history_module, HistoryStub)

    Application.put_env(:petal_boilerplate, :catalog_test_recent_events, [
      %{
        "model_key" => "#{target_model.provider}:#{target_model.model_id}",
        "captured_at" => captured_at,
        "type" => "changed",
        "changes" => [%{"path" => "limits.context"}]
      }
    ])

    :persistent_term.put({Catalog, :models}, stale_models)
    :persistent_term.put({Catalog, :model_count}, length(stale_models))

    refreshed_model =
      Catalog.list_all_models()
      |> Enum.find(fn model ->
        model.provider == target_model.provider and model.model_id == target_model.model_id
      end)

    assert refreshed_model.__last_changed_at == captured_at
    assert is_integer(refreshed_model.__last_changed_epoch)
  end

  test "direct lookup returns models by provider/model_id and dom id" do
    model = Catalog.list_all_models() |> List.first()
    model_dom_id = model.id
    model_id = model.model_id

    assert %{id: ^model_dom_id} = Catalog.get_model(to_string(model.provider), model_id)
    assert %{model_id: ^model_id} = Catalog.get_model_by_dom_id(model_dom_id)
  end

  test "query_models matches list_models plus paginate" do
    filters = Catalog.default_filters()
    sort = %{by: :recently_changed, dir: :desc}

    expected =
      Catalog.list_all_models()
      |> Catalog.list_models(filters, sort)
      |> Catalog.paginate(2)

    assert Catalog.query_models(filters, sort, 2) == expected
  end

  test "list_models filters by required input and output modalities" do
    filters = %{
      Catalog.default_filters()
      | modalities_in: MapSet.new([:image, :audio]),
        modalities_out: MapSet.new([:audio])
    }

    models = [
      build_model("text-only", [:text], [:text]),
      build_model("image-to-text", [:text, :image], [:text]),
      build_model("multimodal-audio", [:text, :image, :audio], [:text, :audio])
    ]

    result = Catalog.list_models(models, filters, Catalog.default_sort())

    assert Enum.map(result, & &1.id) == ["multimodal-audio"]
  end

  defp restore_env(key, nil), do: Application.delete_env(:petal_boilerplate, key)
  defp restore_env(key, value), do: Application.put_env(:petal_boilerplate, key, value)

  defp build_model(id, input_modalities, output_modalities) do
    %{
      id: id,
      provider: :test_provider,
      deprecated: false,
      __provider_str: "test_provider",
      __search: id,
      __allowed?: true,
      __caps: MapSet.new(),
      __in: MapSet.new(input_modalities),
      __out: MapSet.new(output_modalities),
      __context: 0,
      __output: 0,
      __cost_in: 0.0,
      __cost_out: 0.0
    }
  end
end
