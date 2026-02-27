defmodule PetalBoilerplateWeb.HistoryControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

  defmodule HistoryOkStub do
    def available?, do: true

    def meta do
      {:ok,
       %{
         "from_commit" => "1111111111111111111111111111111111111111",
         "to_commit" => "2222222222222222222222222222222222222222",
         "generated_at" => "2026-02-27T00:00:00Z"
       }}
    end

    def timeline(_provider, _model_id, _limit) do
      {:ok,
       [
         %{
           "schema_version" => 1,
           "type" => "changed",
           "captured_at" => "2026-02-01T00:00:00Z",
           "changes" => [
             %{"path" => "limits.context"},
             %{"path" => "cost.input"}
           ]
         }
       ]}
    end

    def recent(_limit) do
      {:ok,
       [
         %{
           "schema_version" => 1,
           "type" => "introduced",
           "captured_at" => "2026-02-01T00:00:00Z",
           "changes" => []
         }
       ]}
    end
  end

  defmodule HistoryUnavailableStub do
    def available?, do: false
    def meta, do: {:error, :history_unavailable}
    def timeline(_provider, _model_id, _limit), do: {:error, :history_unavailable}
    def recent(_limit), do: {:error, :history_unavailable}
  end

  defmodule HistoryEmptyStub do
    def available?, do: true

    def meta do
      {:ok, %{"from_commit" => "a", "to_commit" => "b", "generated_at" => "2026-02-27T00:00:00Z"}}
    end

    def timeline(_provider, _model_id, _limit), do: {:ok, []}
    def recent(_limit), do: {:ok, []}
  end

  defmodule HistoryInvalidLimitStub do
    def available?, do: true

    def meta,
      do:
        {:ok,
         %{"from_commit" => "a", "to_commit" => "b", "generated_at" => "2026-02-27T00:00:00Z"}}

    def timeline(_provider, _model_id, _limit), do: {:error, :invalid_limit}
    def recent(_limit), do: {:error, :invalid_limit}
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

  test "GET /api/history/recent returns recent history contract", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryOkStub)

    conn = get(conn, "/api/history/recent?limit=50")

    assert %{
             "schema_version" => 1,
             "recent" => true,
             "events" => events,
             "meta" => %{
               "from_commit" => "1111111111111111111111111111111111111111",
               "to_commit" => "2222222222222222222222222222222222222222",
               "generated_at" => "2026-02-27T00:00:00Z"
             }
           } = json_response(conn, 200)

    assert [%{"type" => "introduced"}] = events
  end

  test "GET /api/history/recent returns 400 for invalid limit", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryInvalidLimitStub)

    conn = get(conn, "/api/history/recent?limit=bad")

    assert %{"error" => "invalid_limit"} = json_response(conn, 400)
  end

  test "GET /api/history/recent returns 503 when history unavailable", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryUnavailableStub)

    conn = get(conn, "/api/history/recent")

    assert %{"error" => "history_unavailable"} = json_response(conn, 503)
  end

  test "GET /api/history/:provider/*id returns model history contract", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryOkStub)

    conn = get(conn, "/api/history/openai/gpt-4o?limit=200")

    assert %{
             "schema_version" => 1,
             "model_key" => "openai:gpt-4o",
             "events" => [%{"type" => "changed"}],
             "meta" => %{"from_commit" => _, "to_commit" => _, "generated_at" => _}
           } = json_response(conn, 200)
  end

  test "GET /api/history/:provider/*id returns 404 for unknown model with no events", %{
    conn: conn
  } do
    Application.put_env(:petal_boilerplate, :history_module, HistoryEmptyStub)

    conn = get(conn, "/api/history/unknown_provider/missing-model")

    assert %{"error" => "model_not_found", "model_key" => "unknown_provider:missing-model"} =
             json_response(conn, 404)
  end

  test "GET /api/history/:provider/*id returns 200 for known model even when events are empty", %{
    conn: conn
  } do
    Application.put_env(:petal_boilerplate, :history_module, HistoryEmptyStub)

    model = Catalog.list_all_models() |> List.first()
    provider = URI.encode(to_string(model.provider))
    model_id = encode_model_id(model.model_id)

    conn = get(conn, "/api/history/#{provider}/#{model_id}")

    assert %{"model_key" => _, "events" => []} = json_response(conn, 200)
  end

  test "GET /api/history/:provider/*id returns 400 for invalid limit", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryInvalidLimitStub)

    conn = get(conn, "/api/history/openai/gpt-4o?limit=wat")

    assert %{"error" => "invalid_limit"} = json_response(conn, 400)
  end

  test "GET /api/history/:provider/*id returns 503 when history unavailable", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :history_module, HistoryUnavailableStub)

    conn = get(conn, "/api/history/openai/gpt-4o")

    assert %{"error" => "history_unavailable"} = json_response(conn, 503)
  end

  defp encode_model_id(model_id) do
    model_id
    |> String.split("/")
    |> Enum.map(&URI.encode/1)
    |> Enum.join("/")
  end
end
