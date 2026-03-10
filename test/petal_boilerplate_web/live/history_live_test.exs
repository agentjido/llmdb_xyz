defmodule PetalBoilerplateWeb.HistoryLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  defmodule HistoryFeedStub do
    def available?, do: true

    def meta do
      {:ok,
       %{
         "from_commit" => "1111111111111111111111111111111111111111",
         "to_commit" => "2222222222222222222222222222222222222222",
         "generated_at" => "2026-03-10T00:00:00Z"
       }}
    end

    def timeline(_provider, _model_id, _limit), do: {:ok, []}

    def recent(_limit) do
      {:ok, Application.get_env(:petal_boilerplate, :history_live_recent_events, [])}
    end
  end

  defmodule HistoryUnavailableStub do
    def available?, do: false
    def meta, do: {:error, :history_unavailable}
    def timeline(_provider, _model_id, _limit), do: {:error, :history_unavailable}
    def recent(_limit), do: {:error, :history_unavailable}
  end

  setup do
    original_history_module = Application.get_env(:petal_boilerplate, :history_module)
    original_recent_events = Application.get_env(:petal_boilerplate, :history_live_recent_events)

    on_exit(fn ->
      restore_env(:history_module, original_history_module)
      restore_env(:history_live_recent_events, original_recent_events)
    end)

    :ok
  end

  test "history page renders reverse-chronological changes and filters by days and type", %{
    conn: conn
  } do
    Application.put_env(:petal_boilerplate, :history_module, HistoryFeedStub)

    now = DateTime.utc_now()

    older_event =
      history_event("anthropic:claude-3-5-sonnet", DateTime.add(now, -15 * 86_400, :second))

    newer_event = history_event("openai:gpt-4o", DateTime.add(now, -2 * 86_400, :second))

    introduced_event =
      history_event("openai:gpt-5.4-pro", DateTime.add(now, -1 * 86_400, :second), "introduced")

    Application.put_env(:petal_boilerplate, :history_live_recent_events, [
      older_event,
      newer_event,
      introduced_event
    ])

    {:ok, _view, html} = live(conn, "/history")

    assert html =~ "History"
    assert html =~ "gpt-4o"
    assert html =~ "claude-3-5-sonnet"
    assert html =~ "gpt-5.4-pro"
    assert position_of(html, "gpt-4o") < position_of(html, "claude-3-5-sonnet")
    assert position_of(html, "gpt-5.4-pro") < position_of(html, "gpt-4o")

    {:ok, _view, filtered_html} = live(conn, "/history?changed=7")

    assert filtered_html =~ "gpt-4o"
    refute filtered_html =~ "claude-3-5-sonnet"

    {:ok, _view, introduced_html} = live(conn, "/history?type=introduced")

    assert introduced_html =~ "gpt-5.4-pro"
    refute introduced_html =~ "gpt-4o"
    refute introduced_html =~ "claude-3-5-sonnet"

    {:ok, _view, changed_html} = live(conn, "/history?changed=7&type=changed")

    assert changed_html =~ "gpt-4o"
    refute changed_html =~ "gpt-5.4-pro"
    refute changed_html =~ "claude-3-5-sonnet"
  end

  test "history page shows unavailable state", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryUnavailableStub)

    {:ok, _view, html} = live(conn, "/history")

    assert html =~ "History is not available for this deployment."
  end

  defp history_event(model_key, captured_at, type \\ "changed") do
    %{
      "model_key" => model_key,
      "type" => type,
      "captured_at" => DateTime.to_iso8601(captured_at),
      "changes" => [
        %{"path" => "limits.context"},
        %{"path" => "cost.input"}
      ]
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
