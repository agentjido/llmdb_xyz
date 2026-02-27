defmodule PetalBoilerplate.HistorySmokeTest do
  use ExUnit.Case, async: false

  test "llm_db is git pinned and runtime history artifacts are available" do
    lock = Mix.Dep.Lock.read()
    assert {:git, _url, commit, opts} = lock[:llm_db]
    assert is_binary(commit)
    assert byte_size(commit) == 40
    assert Keyword.get(opts, :branch) == "main"

    meta_path = Application.app_dir(:llm_db, "priv/llm_db/history/meta.json")
    assert File.exists?(meta_path)
    assert LLMDB.History.available?()
  end
end
