defmodule PetalBoilerplateWeb.OGImageControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.OGImage

  setup do
    OGImage.clear_cache()

    on_exit(fn ->
      OGImage.clear_cache()
    end)

    :ok
  end

  test "GET /og/home.png returns image headers for crawler hygiene", %{conn: conn} do
    conn = get(conn, "/og/home.png")

    assert response(conn, 200)
    assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
    assert get_resp_header(conn, "x-robots-tag") == ["noindex, noimageindex"]
    assert Enum.any?(get_resp_header(conn, "content-type"), &String.starts_with?(&1, "image/png"))
  end

  test "GET /og/model/:provider/*id returns a model image with crawler headers", %{conn: conn} do
    model = Catalog.list_all_models() |> List.first()

    path =
      model.model_id
      |> String.split("/")
      |> Enum.map(&URI.encode/1)
      |> Enum.join("/")
      |> then(fn encoded_model_id ->
        "/og/model/#{URI.encode(to_string(model.provider))}/#{encoded_model_id}.png"
      end)

    conn = get(conn, path)

    assert response(conn, 200)
    assert get_resp_header(conn, "x-robots-tag") == ["noindex, noimageindex"]
    assert Enum.any?(get_resp_header(conn, "content-type"), &String.starts_with?(&1, "image/png"))
  end
end
