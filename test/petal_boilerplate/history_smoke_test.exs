defmodule PetalBoilerplate.HistorySmokeTest do
  use ExUnit.Case, async: false

  test "llm_db is pinned to a release tag and runtime history artifacts are available" do
    lock = Mix.Dep.Lock.read()
    assert {:git, _url, commit, opts} = lock[:llm_db]
    assert is_binary(commit)
    assert byte_size(commit) == 40

    tag = Keyword.get(opts, :tag)
    assert is_binary(tag)
    assert {:ok, _version} = Version.parse(tag)

    meta_path = Application.app_dir(:llm_db, "priv/llm_db/history/meta.json")
    assert File.exists?(meta_path)
    assert LLMDB.History.available?()
    assert {:ok, meta} = PetalBoilerplate.History.meta()
    assert is_binary(meta["generated_at"])
    assert meta["range_kind"] in ["commits", "snapshots"]
    assert is_binary(meta["from_ref"])
    assert is_binary(meta["to_ref"])
  end
end
