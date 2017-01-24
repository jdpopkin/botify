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
    cond do
      Regex.match?(~r'https://(open|play).spotify.com/track/', message.text) ->
        handle_track_link(message)
      Regex.match?(~r'https://(open|play).spotify.com/album/', message.text) ->
        handle_album_link(message)
      true -> nil
    end
  end
  defp handle_message(_, _) do
    nil
  end

  defp handle_track_link(message) do
    {:ok, track_id} = Regex.run(
        ~r'https://(open|play).spotify.com/track/([^\s>]*)',
        message.text
      ) |> Enum.fetch(2)

    update_spotify(track_id)

    add_note(message)
  end

  defp handle_album_link(message) do
    {:ok, album_id} = Regex.run(
        ~r'https://(open|play).spotify.com/album/([^\s>]*)',
        message.text
      ) |> Enum.fetch(2)

    track_id = most_popular_on_album(album_id)

    update_spotify(track_id)
    add_note(message)
  end

  defp most_popular_on_album(album_id) do
    credentials = fetch_and_refresh_credentials()

    {:ok, album} = Spotify.Album.get_album(credentials, album_id)
    song_count = album.tracks.total

    # in fifty-song chunks due to Spotify API limitations
    songs = Enum.flat_map(0..(div(song_count, 50)), fn(n) ->
      {:ok, page} = Spotify.Album.get_album_tracks(
                        credentials,
                        album_id,
                        %{limit: 50, offset: 50 * n}
                    )
      page.items
      #|> Enum.map(fn(i) -> i.track end)
    end)

    song = Enum.max_by(songs, fn(s) -> s.popularity end)
    song.id
  end

  defp add_note(message) do
    options = %{channel: message.channel, timestamp: message.ts, token: System.get_env("SLACK_TOKEN")}
    Slack.Web.Reactions.add('musical_note', options)
  end

  defp fetch_and_refresh_credentials() do
    db_credentials = fetch_credentials()
    refresh_if_necessary(db_credentials, System.get_env("SPOTIFY_USER"))
  end

  # TODO Extract a new module for this stuff
  defp update_spotify(track_id) do
    #db_credentials = fetch_credentials()
    #credentials = refresh_if_necessary(db_credentials, System.get_env("SPOTIFY_USER"))
    credentials = fetch_and_refresh_credentials()

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
          {:ok, new_credentials} ->
            # Reuse old refresh token because a Spotify refresh response will
            # not contain the refresh token
            Spotify.Credentials.new(new_credentials.access_token, credentials.refresh_token)
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
