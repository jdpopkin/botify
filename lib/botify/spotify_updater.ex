defmodule Botify.SpotifyUpdater do

  def add_track(track_id) do
    credentials = fetch_and_refresh_credentials()

    Spotify.Playlist.add_tracks(
      credentials,
      System.get_env("SPOTIFY_USER"),
      System.get_env("SPOTIFY_PLAYLIST"),
      uris: "spotify:track:#{track_id}"
    )
  end

  defp fetch_and_refresh_credentials() do
    db_credentials = fetch_credentials()
    refresh_if_necessary(db_credentials, System.get_env("SPOTIFY_USER"))
  end

  def most_popular_on_album(album_id) do
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

end
