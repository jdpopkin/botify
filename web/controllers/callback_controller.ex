defmodule Botify.CallbackController do
  use Botify.Web, :controller

  def index(conn, params) do
    {:ok, credentials} = Spotify.Authentication.authenticate(%Spotify.Credentials{}, params)
    persist_credentials(credentials)
    render conn, "index.html"
  end

  # TODO Move this somewhere reusable so the Slackbot can call it
  # TODO on 401 response
  defp persist_credentials(credentials) do
    case update_credentials(credentials) do
      {0, _} -> insert_credentials(credentials)
      {_, _} -> nil
    end
  end

  defp update_credentials(credentials) do
    Botify.Repo.update_all(Botify.Credentials, set: [
                                   access_token: credentials.access_token,
                                   refresh_token: credentials.refresh_token,
                                 ])
  end
  defp insert_credentials(credentials) do
    Botify.Repo.insert(%Botify.Credentials{
                               access_token: credentials.access_token,
                               refresh_token: credentials.refresh_token
                             })
  end
end
