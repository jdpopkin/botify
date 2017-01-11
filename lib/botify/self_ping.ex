defmodule Botify.SelfPing do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    handle_info(:work, state)
    {:ok, state}
  end

  def handle_info(:work, state) do
    HTTPoison.get(System.get_env("APP_URL"))
    IO.puts("Pinged.")

    schedule_work()
    {:noreply, state}
  end

  def schedule_work do
    Process.send_after(self(), :work, 1000 * 60 * 29)
  end
end
