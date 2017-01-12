defmodule Botify.SlackRtm do
  use Slack

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    target_channel = System.get_env("SLACK_CHANNEL")
    case message.channel do
      ^target_channel -> handle_message(message, slack)
      _ -> nil
    end

    {:ok, state}
  end
  def handle_event(_, _, state), do: {:ok, state}

  defp handle_message(message = %{text: _}, _slack) do
    is_track_link = Regex.match?(~r'https://(open|play).spotify.com/track/', message.text)

    if is_track_link do
      update_spotify(message)

      options = %{channel: message.channel, timestamp: message.ts, token: System.get_env("SLACK_TOKEN")}
      Slack.Web.Reactions.add('musical_note', options)
      nil
    end
  end
  defp handle_message(_, _) do
    nil
  end

  # TODO Extract a new module for this stuff
  defp update_spotify(message) do
    db_credentials = fetch_credentials()
    credentials = refresh_if_necessary(db_credentials, System.get_env("SPOTIFY_USER"))

    {:ok, track_id} = Regex.run(~r'https://(open|play).spotify.com/track/([^\s>]*)', message.text) |> Enum.fetch(2)
    Spotify.Playlist.add_tracks(
                                credentials,
                                System.get_env("SPOTIFY_USER"),
                                System.get_env("SPOTIFY_PLAYLIST"),
                                uris: "spotify:track:#{track_id}"
                              )
  end

  defp refresh_if_necessary(credentials, user_id) do
    {:ok, response} = Spotify.Playlist.get_users_playlists(credentials, user_id)

    case response do
      %{"error" => %{"status" => 401}} ->
        case Spotify.Authentication.refresh(credentials) do
          {:ok, new_credentials} -> new_credentials
          _ ->
            IO.puts("Refresh failed! Reauthentication required.")
            credentials
        end
      _ -> credentials
    end
  end
  defp fetch_credentials do
    import Ecto.Query

    query = from(c in Botify.Credentials, select: %{access: c.access_token, refresh: c.refresh_token})
    results = Botify.Repo.all(query)

    case results do
      [row] ->
        Spotify.Credentials.new(row[:access], row[:refresh])
      [] -> nil
    end
  end

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}
end
