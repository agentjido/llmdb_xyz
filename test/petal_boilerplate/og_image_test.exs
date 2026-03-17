defmodule PetalBoilerplate.OGImageTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.OGImage

  @model_cache_ttl_ms :timer.hours(1)

  setup do
    Catalog.refresh_cache()
    OGImage.clear_cache()

    on_exit(fn ->
      OGImage.clear_cache()
    end)

    :ok
  end

  test "missing model falls back to the shared default image without caching a model key" do
    assert {:ok, default_png} = OGImage.get_image(:default)
    assert {:ok, png} = OGImage.get_image({:model, "missing-provider", "missing-model"})

    assert png == default_png
    refute :ets.member(:og_image_cache, "model:missing-provider:missing-model")
  end

  test "expired model cache entries are purged before inserting a new model image" do
    now = System.system_time(:millisecond)
    expired_at = now - 1

    :ets.insert(
      :og_image_cache,
      {"model:expired:entry", :model, <<1, 2, 3>>, expired_at - 10, expired_at - 10, expired_at}
    )

    model = Catalog.list_all_models() |> List.first()

    assert {:ok, _png} = OGImage.get_image({:model, to_string(model.provider), model.model_id})
    refute :ets.member(:og_image_cache, "model:expired:entry")
  end

  test "model cache evicts the least recently used entry when it reaches the cap" do
    now = System.system_time(:millisecond)

    for index <- 1..250 do
      last_access_at = now - (1_000 + index)

      :ets.insert(
        :og_image_cache,
        {"model:preloaded:#{index}", :model, <<index::16>>, last_access_at, last_access_at,
         now + @model_cache_ttl_ms}
      )
    end

    model = Catalog.list_all_models() |> List.first()
    cache_key = "model:#{model.provider}:#{model.model_id}"

    assert {:ok, _png} = OGImage.get_image({:model, to_string(model.provider), model.model_id})
    assert :ets.info(:og_image_cache, :size) == 250
    refute :ets.member(:og_image_cache, "model:preloaded:250")
    assert :ets.member(:og_image_cache, cache_key)
  end
end
