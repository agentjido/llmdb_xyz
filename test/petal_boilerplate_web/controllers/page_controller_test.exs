defmodule PetalBoilerplateWeb.PageControllerTest do
  use PetalBoilerplateWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "<main>"
    assert html =~ ~s(href="/compare-subs")
  end
end
