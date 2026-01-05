defmodule PetalBoilerplateWeb.OgMetaTest do
  use PetalBoilerplateWeb.ConnCase

  describe "OpenGraph meta tags" do
    test "home page has correct OG tags", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ ~s(property="og:title" content="LLM Model Database")
      assert html =~ ~s(property="og:description" content="Browse and compare 2,000+)
      assert html =~ ~s(property="og:url" content="https://llmdb.xyz/")
      assert html =~ ~s(property="og:type" content="website")
      assert html =~ ~s(property="og:image")
    end

    test "about page has correct OG tags", %{conn: conn} do
      conn = get(conn, ~p"/about")
      html = html_response(conn, 200)

      assert html =~ ~s(property="og:title" content="About")
      assert html =~ ~s(property="og:description" content="Learn about llmdb.xyz)
      assert html =~ ~s(property="og:url" content="https://llmdb.xyz/about")
    end

    test "model detail page has correct OG tags", %{conn: conn} do
      conn = get(conn, ~p"/models/openai/gpt-4o")
      html = html_response(conn, 200)

      assert html =~ ~s(property="og:title" content="GPT-4o - openai")
      assert html =~ ~s(property="og:description")
      assert html =~ ~s(property="og:url" content="https://llmdb.xyz/models/openai/gpt-4o")
    end

    test "non-existent model shows not found OG tags", %{conn: conn} do
      conn = get(conn, ~p"/models/fake-provider/fake-model")
      html = html_response(conn, 200)

      assert html =~ ~s(property="og:title" content="Model Not Found")
      assert html =~ ~s(property="og:description" content="The requested model could not be found.")
    end

    test "Twitter card tags are present", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ ~s(name="twitter:card" content="summary_large_image")
      assert html =~ ~s(name="twitter:title")
      assert html =~ ~s(name="twitter:description")
      assert html =~ ~s(name="twitter:image")
    end
  end
end
