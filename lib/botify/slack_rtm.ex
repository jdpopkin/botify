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
      options = %{channel: message.channel, timestamp: message.ts, token: System.get_env("SLACK_TOKEN")}
      Slack.Web.Reactions.add('musical_note', options)
      nil
    end
  end
  defp handle_message(_, _) do
    nil
  end

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}
end
