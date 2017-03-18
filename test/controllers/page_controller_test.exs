defmodule Botify.PageControllerTest do
  use Botify.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ ~r".*<a href=\"https://accounts.spotify.com/authorize.*"s
  end
end
