defmodule PetalBoilerplate.History do
  @moduledoc """
  Wrapper around `LLMDB.History` with app-level defaults and limit validation.
  """

  require Logger

  @default_timeline_limit 200
  @default_recent_limit 50
  @max_limit 500
  @history_archive_name "petal_boilerplate-llm_db-history.tar.gz"

  alias LLMDB.{History.Bundle, Snapshot, Snapshot.ReleaseStore}

  @doc """
  Configures a writable history directory and syncs the published bundle when needed.
  """
  def configure_runtime_bundle do
    history_dir = history_dir()
    Application.put_env(:llm_db, :history_dir, history_dir)

    case ensure_local_bundle(history_dir) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("llm_db history bundle unavailable: #{inspect(reason)}")
        :ok
    end
  end

  @doc """
  Returns the configured local history directory.
  """
  def history_dir do
    System.get_env("LLMDB_HISTORY_DIR") ||
      Path.join([System.tmp_dir!(), "petal_boilerplate", "llm_db", "history"])
  end

  @doc """
  Returns whether runtime history artifacts are available.
  """
  def available? do
    LLMDB.History.available?()
  end

  @doc """
  Returns compact history metadata for API/UI consumers.
  """
  def meta do
    with {:ok, meta} <- LLMDB.History.meta() do
      {:ok, compact_meta(meta)}
    end
  end

  @doc """
  Returns model timeline events with a validated limit.
  """
  def timeline(provider, model_id, limit \\ @default_timeline_limit) when is_binary(model_id) do
    with {:ok, normalized_limit} <- normalize_limit(limit),
         {:ok, events} <- LLMDB.History.timeline(provider, model_id) do
      {:ok, Enum.take(events, -normalized_limit)}
    end
  end

  @doc """
  Returns recent events with a validated limit.
  """
  def recent(limit \\ @default_recent_limit) do
    with {:ok, normalized_limit} <- normalize_limit(limit) do
      LLMDB.History.recent(normalized_limit)
    end
  end

  defp compact_meta(meta) do
    from_commit = map_get(meta, "from_commit", :from_commit)
    to_commit = map_get(meta, "to_commit", :to_commit)
    from_snapshot_id = map_get(meta, "from_snapshot_id", :from_snapshot_id)
    to_snapshot_id = map_get(meta, "to_snapshot_id", :to_snapshot_id)

    {range_kind, from_ref, to_ref} =
      cond do
        is_binary(from_snapshot_id) and is_binary(to_snapshot_id) ->
          {"snapshots", from_snapshot_id, to_snapshot_id}

        is_binary(from_commit) and is_binary(to_commit) ->
          {"commits", from_commit, to_commit}

        true ->
          {nil, nil, nil}
      end

    %{
      "from_commit" => map_get(meta, "from_commit", :from_commit),
      "to_commit" => map_get(meta, "to_commit", :to_commit),
      "from_snapshot_id" => from_snapshot_id,
      "to_snapshot_id" => to_snapshot_id,
      "from_ref" => from_ref,
      "to_ref" => to_ref,
      "range_kind" => range_kind,
      "generated_at" => map_get(meta, "generated_at", :generated_at),
      "snapshots_written" => map_get(meta, "snapshots_written", :snapshots_written),
      "unique_snapshots_written" =>
        map_get(meta, "unique_snapshots_written", :unique_snapshots_written),
      "events_written" => map_get(meta, "events_written", :events_written)
    }
  end

  defp normalize_limit(limit) when is_integer(limit) and limit > 0 do
    {:ok, min(limit, @max_limit)}
  end

  defp normalize_limit(limit) when is_binary(limit) do
    limit
    |> String.trim()
    |> parse_limit()
  end

  defp normalize_limit(_), do: {:error, :invalid_limit}

  defp parse_limit(""), do: {:error, :invalid_limit}

  defp parse_limit(limit) do
    case Integer.parse(limit) do
      {parsed, ""} -> normalize_limit(parsed)
      _ -> {:error, :invalid_limit}
    end
  end

  defp map_get(map, string_key, atom_key) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp ensure_local_bundle(history_dir) do
    with {:ok, snapshot_id} <- packaged_snapshot_id(),
         true <- history_current?(history_dir, snapshot_id) do
      :ok
    else
      false -> sync_history_bundle(history_dir)
      {:error, _reason} = error -> error
    end
  end

  defp packaged_snapshot_id do
    case Snapshot.read(Snapshot.packaged_path()) do
      {:ok, %{"snapshot_id" => snapshot_id}} when is_binary(snapshot_id) -> {:ok, snapshot_id}
      {:ok, _snapshot} -> {:error, :missing_snapshot_id}
      {:error, reason} -> {:error, reason}
    end
  end

  defp history_current?(history_dir, snapshot_id) do
    case Bundle.read_meta(history_dir) do
      {:ok, %{"to_snapshot_id" => ^snapshot_id}} -> true
      _ -> false
    end
  end

  defp sync_history_bundle(history_dir) do
    archive_path = Path.join(System.tmp_dir!(), @history_archive_name)

    try do
      with :ok <- ReleaseStore.download_history_archive(archive_path),
           :ok <- replace_history_bundle(archive_path, history_dir) do
        :ok
      else
        {:error, reason} ->
          File.rm_rf(history_dir)
          {:error, reason}
      end
    after
      File.rm(archive_path)
    end
  end

  defp replace_history_bundle(archive_path, history_dir) do
    File.rm_rf(history_dir)
    Bundle.install_archive(archive_path, history_dir)
  end
end
