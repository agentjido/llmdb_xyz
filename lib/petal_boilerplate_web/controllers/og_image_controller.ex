defmodule PetalBoilerplateWeb.OGImageController do
  @moduledoc """
  Serves Open Graph images for social media sharing.

  Generates PNG images dynamically and caches them for fast retrieval.
  Images are 1200x630 pixels, optimized for social media platforms.
  """

  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplate.OGImage

  def default(conn, _params) do
    serve_image(conn, OGImage.get_image(:default))
  end

  def home(conn, _params) do
    serve_image(conn, OGImage.get_image(:home))
  end

  def about(conn, _params) do
    serve_image(conn, OGImage.get_image(:about))
  end

  def model(conn, %{"provider" => provider, "id" => id_parts}) do
    id = id_parts |> List.wrap() |> Enum.join("/") |> String.trim_trailing(".png")
    serve_image(conn, OGImage.get_image({:model, provider, id}))
  end

  defp serve_image(conn, {:ok, png_data}) do
    conn
    |> put_resp_content_type("image/png")
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> send_resp(200, png_data)
  end

  defp serve_image(conn, {:error, _reason}) do
    fallback_path =
      Application.app_dir(:petal_boilerplate, "priv/static/images/og-default.png")

    case File.read(fallback_path) do
      {:ok, png} ->
        conn
        |> put_resp_content_type("image/png")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, png)

      {:error, _} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(500, "Error generating image")
    end
  end
end
