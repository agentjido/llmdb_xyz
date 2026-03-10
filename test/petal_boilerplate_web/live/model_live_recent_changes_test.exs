defmodule PetalBoilerplateWeb.ModelLiveRecentChangesTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

  defmodule HistoryTimelineEnvStub do
    def available?, do: true

    def meta do
      {:ok,
       %{
         "from_commit" => "1111111111111111111111111111111111111111",
         "to_commit" => "2222222222222222222222222222222222222222",
         "generated_at" => "2026-03-10T00:00:00Z"
       }}
    end

    def recent(_limit) do
      {:ok, Application.get_env(:petal_boilerplate, :model_live_recent_events, [])}
    end

    def timeline(provider, model_id, _limit) do
      events =
        Application.get_env(:petal_boilerplate, :model_live_timeline_events, %{})
        |> Map.get("#{provider}:#{model_id}", [])

      {:ok, events}
    end
  end

  setup do
    original_history_module = Application.get_env(:petal_boilerplate, :history_module)
    original_recent_events = Application.get_env(:petal_boilerplate, :model_live_recent_events)

    original_timeline_events =
      Application.get_env(:petal_boilerplate, :model_live_timeline_events)

    models = Catalog.list_all_models() |> Enum.take(3)
    [recent_model, older_model, untouched_model] = models
    now = DateTime.utc_now()

    timeline_events = %{
      model_key(recent_model) => [history_event(DateTime.add(now, -2 * 86_400, :second))],
      model_key(older_model) => [history_event(DateTime.add(now, -20 * 86_400, :second))]
    }

    recent_events = [
      history_event(DateTime.add(now, -2 * 86_400, :second), model_key(recent_model)),
      history_event(DateTime.add(now, -20 * 86_400, :second), model_key(older_model))
    ]

    Application.put_env(:petal_boilerplate, :history_module, HistoryTimelineEnvStub)
    Application.put_env(:petal_boilerplate, :model_live_timeline_events, timeline_events)
    Application.put_env(:petal_boilerplate, :model_live_recent_events, recent_events)
    Catalog.refresh_cache()

    on_exit(fn ->
      restore_env(:history_module, original_history_module)
      restore_env(:model_live_recent_events, original_recent_events)
      restore_env(:model_live_timeline_events, original_timeline_events)
      Catalog.refresh_cache()
    end)

    {:ok, recent_model: recent_model, older_model: older_model, untouched_model: untouched_model}
  end

  test "catalog filters models changed in the last 7 days", %{
    conn: conn,
    recent_model: recent_model,
    older_model: older_model,
    untouched_model: untouched_model
  } do
    {:ok, _view, html} = live(conn, "/?changed=7")

    assert html =~ recent_model.model_id
    refute html =~ older_model.model_id
    refute html =~ untouched_model.model_id
    assert html =~ "Changed in 7d"
  end

  test "catalog sorts models by most recent change first", %{
    conn: conn,
    recent_model: recent_model,
    older_model: older_model
  } do
    {:ok, _view, html} = live(conn, "/?sort=recently_changed&dir=desc")

    assert position_of(html, recent_model.model_id) < position_of(html, older_model.model_id)
  end

  defp model_key(model), do: "#{model.provider}:#{model.model_id}"

  defp history_event(captured_at, model_key \\ nil) do
    %{
      "model_key" => model_key,
      "captured_at" => DateTime.to_iso8601(captured_at),
      "type" => "changed",
      "changes" => [%{"path" => "limits.context"}]
    }
  end

  defp position_of(html, needle) do
    case :binary.match(html, needle) do
      {position, _length} -> position
      :nomatch -> flunk("expected #{inspect(needle)} to appear in rendered HTML")
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:petal_boilerplate, key)
  defp restore_env(key, value), do: Application.put_env(:petal_boilerplate, key, value)
end
