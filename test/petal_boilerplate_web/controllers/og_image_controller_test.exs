defmodule PetalBoilerplateWeb.OGImageControllerTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  test "GET /og/compare-subs.png returns PNG image", %{conn: conn} do
    conn = get(conn, "/og/compare-subs.png")

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> List.first() =~ "image/png"
  end
end
