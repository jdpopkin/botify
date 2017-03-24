defmodule Botify.SlackRtmTest do
  use ExUnit.Case, async: false

  import Mock

  test "only handle messages" do
    with_mock System, [get_env: fn(_) -> "unused" end] do
      Botify.SlackRtm.handle_event(%{foo: "bar"}, nil, nil)
      # Signifies no action taken
      assert !called(System.get_env(:_))
    end
  end

  test "only handle messages in the configured channel" do
    with_mocks([
      {System,
       [],
       [get_env: fn("SLACK_CHANNEL") -> "asdf" end]},
      {Regex,
       [],
       [match?: fn(_, _) -> false end]}
    ]) do
      Botify.SlackRtm.handle_event(
        %{type: "message", text: "foo", channel: "bar"}, nil, nil
      )
      # Signifies no action taken
      assert !called(Regex.match?(:_, :_))
    end
  end

  test "handles links to tracks" do
    with_mocks([
      {System,
        [],
       [get_env: fn
         "SLACK_CHANNEL" -> "botify"
         "SLACK_TOKEN" -> "123321"
       end]},
      {Botify.SpotifyUpdater,
        [],
        [add_track: fn(track) -> "#{track} added!" end]}
    ]) do
      Botify.SlackRtm.handle_event(
        %{
          type: "message",
          text: "I like https://open.spotify.com/track/5H7bGLezMnhxcw7EoaPfsc",
          channel: "botify",
          ts: "123321"
        },
        nil,
        nil
      )
      assert called Botify.SpotifyUpdater.add_track("5H7bGLezMnhxcw7EoaPfsc")
    end
  end

  test "handles links to albums" do
    with_mocks([
      {System,
       [],
       [get_env: fn
         "SLACK_CHANNEL" -> "botify"
         "SLACK_TOKEN" -> "123321"
       end]},
      {Botify.SpotifyUpdater,
       [],
       [add_track: fn(track) -> "#{track} added!" end,
       most_popular_on_album: fn(_album) -> "some_track_id" end]}
    ]) do
      Botify.SlackRtm.handle_event(
        %{
          type: "message",
          text: "I like https://play.spotify.com/album/asdf1234",
          channel: "botify",
          ts: "123321"
        },
        nil,
        nil
      )
      assert called Botify.SpotifyUpdater.add_track("some_track_id")
    end
  end

  test "handles links to playlists" do
    with_mocks([
      {System,
       [],
       [get_env: fn
         "SLACK_CHANNEL" -> "botify"
         "SLACK_TOKEN" -> "123321"
       end]},
      {Botify.SpotifyUpdater,
       [],
       [add_track: fn(track) -> "#{track} added!" end,
        most_popular_in_playlist: fn(_user_id, _playlist) -> "some_track_id" end]}
    ]) do
      Botify.SlackRtm.handle_event(
        %{
          type: "message",
          text: "I like https://play.spotify.com/user/foo/playlist/asdf1234",
          channel: "botify",
          ts: "123321"
        },
        nil,
        nil
      )
      assert called Botify.SpotifyUpdater.add_track("some_track_id")
    end
  end
end
