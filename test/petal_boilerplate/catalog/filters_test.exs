defmodule PetalBoilerplate.Catalog.FiltersTest do
  use ExUnit.Case, async: true

  alias PetalBoilerplate.Catalog.Filters

  describe "new/0" do
    test "creates a filter struct with defaults" do
      filters = Filters.new()

      assert %Filters{} = filters
      assert filters.search == ""
      assert filters.provider_ids == MapSet.new()
      assert filters.min_context == nil
      assert filters.max_cost_in == nil
      assert filters.show_deprecated == false
      assert filters.allowed_only == true
      assert is_map(filters.capabilities)
    end
  end

  describe "from_params/1" do
    test "parses empty params" do
      filters = Filters.from_params(%{})

      assert filters.search == ""
      assert filters.provider_ids == MapSet.new()
    end

    test "parses search from 'search' or 'q'" do
      assert Filters.from_params(%{"search" => "test"}).search == "test"
      assert Filters.from_params(%{"q" => "query"}).search == "query"
    end

    test "parses provider_ids from comma-separated string" do
      filters = Filters.from_params(%{"providers" => "openai,anthropic"})
      assert MapSet.member?(filters.provider_ids, "openai")
      assert MapSet.member?(filters.provider_ids, "anthropic")
    end

    test "parses provider_ids from map" do
      filters =
        Filters.from_params(%{"providers" => %{"openai" => "true", "anthropic" => "true"}})

      assert MapSet.member?(filters.provider_ids, "openai")
      assert MapSet.member?(filters.provider_ids, "anthropic")
    end

    test "parses min_context from 'ctx' or 'min_context'" do
      assert Filters.from_params(%{"ctx" => "100000"}).min_context == 100_000
      assert Filters.from_params(%{"min_context" => "50000"}).min_context == 50_000
    end

    test "parses max_cost_in from 'cost' or 'max_cost_in'" do
      assert Filters.from_params(%{"cost" => "1.5"}).max_cost_in == 1.5
      assert Filters.from_params(%{"max_cost_in" => "2.0"}).max_cost_in == 2.0
    end

    test "parses boolean flags" do
      filters = Filters.from_params(%{"show_deprecated" => "true", "allowed_only" => "false"})
      assert filters.show_deprecated == true
      assert filters.allowed_only == false
    end

    test "parses capability params" do
      filters = Filters.from_params(%{"cap_chat" => "true", "cap_tools" => "true"})
      assert filters.capabilities.chat == true
      assert filters.capabilities.tools == true
    end
  end

  describe "to_params/1" do
    test "serializes empty filters to empty map" do
      filters = Filters.new()
      params = Filters.to_params(filters)

      assert params == %{}
    end

    test "serializes search query" do
      filters = %{Filters.new() | search: "test query"}
      params = Filters.to_params(filters)

      assert params["q"] == "test query"
    end

    test "serializes provider_ids as comma-separated" do
      filters = %{Filters.new() | provider_ids: MapSet.new(["openai", "anthropic"])}
      params = Filters.to_params(filters)

      assert is_binary(params["providers"])
      assert String.contains?(params["providers"], "openai")
      assert String.contains?(params["providers"], "anthropic")
    end

    test "serializes min_context" do
      filters = %{Filters.new() | min_context: 100_000}
      params = Filters.to_params(filters)

      assert params["ctx"] == 100_000
    end

    test "serializes max_cost_in" do
      filters = %{Filters.new() | max_cost_in: 1.0}
      params = Filters.to_params(filters)

      assert params["cost"] == 1.0
    end
  end

  describe "toggle_capability/2" do
    test "toggles capability on" do
      filters = Filters.new()
      filters = Filters.toggle_capability(filters, :tools)

      assert filters.capabilities.tools == true
    end

    test "toggles capability off" do
      filters = Filters.new()
      filters = Filters.toggle_capability(filters, :tools)
      filters = Filters.toggle_capability(filters, :tools)

      assert filters.capabilities.tools == false
    end
  end

  describe "toggle_modality_in/2" do
    test "adds modality to set" do
      filters = Filters.new()
      filters = Filters.toggle_modality_in(filters, :image)

      assert MapSet.member?(filters.modalities_in, :image)
    end

    test "removes modality from set" do
      filters = Filters.new()
      filters = Filters.toggle_modality_in(filters, :image)
      filters = Filters.toggle_modality_in(filters, :image)

      refute MapSet.member?(filters.modalities_in, :image)
    end
  end

  describe "set_providers/2" do
    test "sets providers from MapSet" do
      filters = Filters.new()
      providers = MapSet.new(["openai", "anthropic"])
      filters = Filters.set_providers(filters, providers)

      assert filters.provider_ids == providers
    end

    test "sets providers from list" do
      filters = Filters.new()
      filters = Filters.set_providers(filters, ["openai", "anthropic"])

      assert MapSet.member?(filters.provider_ids, "openai")
      assert MapSet.member?(filters.provider_ids, "anthropic")
    end
  end

  describe "clear_providers/1" do
    test "clears all provider filters" do
      filters = Filters.new()
      filters = Filters.set_providers(filters, ["openai", "anthropic"])
      filters = Filters.clear_providers(filters)

      assert MapSet.size(filters.provider_ids) == 0
    end
  end

  describe "apply_quick_filter/2" do
    test "applies tools quick filter" do
      filters = Filters.new()
      filters = Filters.apply_quick_filter(filters, :tools)

      assert filters.capabilities.tools == true
    end

    test "applies vision quick filter" do
      filters = Filters.new()
      filters = Filters.apply_quick_filter(filters, :vision)

      assert MapSet.member?(filters.modalities_in, :image)
    end

    test "applies context_100k quick filter" do
      filters = Filters.new()
      filters = Filters.apply_quick_filter(filters, :context_100k)

      assert filters.min_context == 100_000
    end

    test "applies budget quick filter" do
      filters = Filters.new()
      filters = Filters.apply_quick_filter(filters, :budget)

      assert filters.max_cost_in == 1.0
    end

    test "toggles quick filter off when applied twice" do
      filters = Filters.new()
      filters = Filters.apply_quick_filter(filters, :context_100k)
      filters = Filters.apply_quick_filter(filters, :context_100k)

      assert filters.min_context == nil
    end

    test "accepts string keys" do
      filters = Filters.new()
      filters = Filters.apply_quick_filter(filters, "tools")

      assert filters.capabilities.tools == true
    end
  end

  describe "active_filter_count/1" do
    test "returns 0 for default filters" do
      filters = Filters.new()
      assert Filters.active_filter_count(filters) == 0
    end

    test "counts search as 1 filter" do
      filters = %{Filters.new() | search: "test"}
      assert Filters.active_filter_count(filters) == 1
    end

    test "counts each provider as 1 filter" do
      filters = %{Filters.new() | provider_ids: MapSet.new(["a", "b", "c"])}
      assert Filters.active_filter_count(filters) == 3
    end

    test "counts each active capability" do
      filters = Filters.new()
      filters = Filters.toggle_capability(filters, :tools)
      filters = Filters.toggle_capability(filters, :chat)
      assert Filters.active_filter_count(filters) == 2
    end
  end

  describe "active_quick_filters/1" do
    test "returns empty list for default filters" do
      filters = Filters.new()
      assert Filters.active_quick_filters(filters) == []
    end

    test "returns active quick filter keys" do
      filters = Filters.new()
      filters = Filters.apply_quick_filter(filters, :tools)
      filters = Filters.apply_quick_filter(filters, :vision)
      active = Filters.active_quick_filters(filters)

      assert :tools in active
      assert :vision in active
    end
  end

  describe "quick_filters/0" do
    test "returns list of quick filter definitions" do
      qf = Filters.quick_filters()

      assert is_list(qf)
      assert length(qf) > 0

      first = hd(qf)
      assert Map.has_key?(first, :key)
      assert Map.has_key?(first, :label)
      assert Map.has_key?(first, :icon)
      assert Map.has_key?(first, :description)
    end
  end

  describe "to_filter_map/1" do
    test "converts struct to map" do
      filters = Filters.new()
      map = Filters.to_filter_map(filters)

      assert is_map(map)
      refute is_struct(map)
      assert Map.has_key?(map, :search)
      assert Map.has_key?(map, :provider_ids)
      assert Map.has_key?(map, :capabilities)
    end
  end

  describe "round-trip parsing" do
    test "from_params -> to_params -> from_params preserves data" do
      original = %{
        "q" => "search term",
        "providers" => "openai,anthropic",
        "ctx" => "100000",
        "cost" => "1.5",
        "cap_tools" => "true",
        "cap_chat" => "true"
      }

      filters1 = Filters.from_params(original)
      params = Filters.to_params(filters1)
      filters2 = Filters.from_params(params)

      assert filters1.search == filters2.search
      assert filters1.min_context == filters2.min_context
      assert filters1.max_cost_in == filters2.max_cost_in
      assert filters1.capabilities.tools == filters2.capabilities.tools
      assert filters1.capabilities.chat == filters2.capabilities.chat
    end
  end
end
