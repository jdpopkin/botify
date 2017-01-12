defmodule Botify.CallbackController do
  use Botify.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
