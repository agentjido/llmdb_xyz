defmodule PetalBoilerplate.HistorySmokeTest do
  use ExUnit.Case, async: false

  test "llm_db is pinned to a Hex release and runtime history artifacts are available" do
    lock = Mix.Dep.Lock.read()
    assert {:hex, :llm_db, version, _checksum, _managers, _deps, "hexpm", _hash} = lock[:llm_db]
    assert {:ok, _version} = Version.parse(version)

    meta_path = Path.join(PetalBoilerplate.History.history_dir(), "meta.json")
    assert File.exists?(meta_path)
    assert LLMDB.History.available?()
    assert {:ok, meta} = PetalBoilerplate.History.meta()
    assert is_binary(meta["generated_at"])
    assert meta["range_kind"] in ["commits", "snapshots"]
    assert is_binary(meta["from_ref"])
    assert is_binary(meta["to_ref"])
  end
end
