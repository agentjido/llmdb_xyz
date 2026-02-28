defmodule PetalBoilerplateWeb.SubscriptionValueLiveTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  test "renders compare-subs page and calculates ranked results", %{conn: conn} do
    {:ok, view, html} = live(conn, "/compare-subs")

    assert html =~ "Subscription Value Calculator"
    refute html =~ "Support open dev tooling"

    params = %{
      "calculator" => %{
        "selected_plan_ids" => ["openai_pro", "openai_plus", "anthropic_max_20x"],
        "workload_profile" => "daily",
        "model_mix_preset" => "balanced",
        "io_input_pct" => "80",
        "band_mode" => "expected"
      }
    }

    html =
      view
      |> form("#subscription-value-form", params)
      |> render_submit()

    assert html =~ "Results"
    assert html =~ "Implied API value band"
    assert html =~ "Support open dev tooling"
  end

  test "manual override applies to opaque plan estimates", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/compare-subs")
    _html = render_click(view, "toggle_advanced")

    params = %{
      "calculator" => %{
        "selected_plan_ids" => ["cursor_pro"],
        "workload_profile" => "daily",
        "model_mix_preset" => "balanced",
        "io_input_pct" => "80",
        "band_mode" => "expected",
        "override_min_units" => "60",
        "override_max_units" => "120"
      }
    }

    html =
      view
      |> form("#subscription-value-form", params)
      |> render_submit()

    assert html =~ "Insufficient precision"
    assert html =~ "manual override applied"
  end
end
