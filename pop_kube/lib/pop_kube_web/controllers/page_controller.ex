defmodule PopKubeWeb.PageController do
  use PopKubeWeb, :controller
  import Phoenix.LiveView.Controller

  def index(conn, _params) do
    live_render(conn, PopKubeWeb.Counter, session: %{
      "ip_address" => to_string(:inet_parse.ntoa(conn.remote_ip))
    })
  end
end
