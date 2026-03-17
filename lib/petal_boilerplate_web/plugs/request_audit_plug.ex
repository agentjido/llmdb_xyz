defmodule PetalBoilerplateWeb.Plug.RequestAudit do
  @moduledoc """
  Logs request details for routes that are useful for traffic attribution.
  """

  import Plug.Conn

  require Logger

  @audited_prefixes ["/models", "/og", "/api/history"]

  def init(opts), do: opts

  def call(conn, _opts) do
    if audited_path?(conn.request_path) do
      started_at = System.monotonic_time()

      register_before_send(conn, fn conn ->
        duration_ms =
          System.monotonic_time()
          |> Kernel.-(started_at)
          |> System.convert_time_unit(:native, :microsecond)
          |> Kernel./(1_000)
          |> Float.round(1)

        Logger.bare_log(:info, fn ->
          "request_audit " <>
            inspect(%{
              request_id: request_id(conn),
              method: conn.method,
              path: conn.request_path,
              status: conn.status,
              duration_ms: duration_ms,
              remote_ip: format_ip(conn.remote_ip),
              x_forwarded_for: header(conn, "x-forwarded-for"),
              user_agent: header(conn, "user-agent")
            })
        end)

        conn
      end)
    else
      conn
    end
  end

  defp audited_path?(path) when is_binary(path) do
    Enum.any?(@audited_prefixes, &String.starts_with?(path, &1))
  end

  defp header(conn, key) do
    conn
    |> get_req_header(key)
    |> List.first()
  end

  defp request_id(conn) do
    get_resp_header(conn, "x-request-id")
    |> List.first()
    |> case do
      nil -> Logger.metadata()[:request_id]
      request_id -> request_id
    end
  end

  defp format_ip(nil), do: nil
  defp format_ip(ip_tuple), do: :inet.ntoa(ip_tuple) |> to_string()
end
