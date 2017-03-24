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
      Regex.match?(~r'https://(open|play).spotify.com/user/[^/]*/playlist/', message.text) ->
        handle_playlist_link(message)
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

    track_id = Botify.SpotifyUpdater.most_popular_on_album(album_id)

    update_spotify(track_id)
    add_note(message)
  end

  defp handle_playlist_link(message) do
    groups = Regex.run(
      ~r'https://(open|play).spotify.com/user/([^/]*)/playlist/([^\s>]*)',
      message.text
    )
    user_id = Enum.fetch!(groups, 2)
    playlist_id = Enum.fetch!(groups, 3)

    track_id = Botify.SpotifyUpdater.most_popular_in_playlist(user_id, playlist_id)

    update_spotify(track_id)
    add_note(message)
  end

  defp update_spotify(track_id) do
    Botify.SpotifyUpdater.add_track(track_id)
  end

  defp add_note(message) do
    options = %{channel: message.channel, timestamp: message.ts, token: System.get_env("SLACK_TOKEN")}
    Slack.Web.Reactions.add('musical_note', options)
  end

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}
end
