defmodule PopKube.Count do
  use GenServer

  alias Phoenix.PubSub
  alias PopKube.Click

  @db_sync_interval 3 # seconds

  def topic do
    "count"
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: PopKube.Count)
  end

  def add_click(ip_address) do
    GenServer.call(PopKube.Count, {:add_click, ip_address})
  end

  def current() do
    GenServer.call(PopKube.Count, :current)
  end

  # ------

  def init(_opts) do
    {:ok, {Click.count(), :os.system_time(:second)}}
  end

  def handle_call(:current, _from, old_state) do
    state = refresh_state(old_state)
    handle_call_reply(state)
  end

  def handle_call({:add_click, ip_address}, _from, old_state) do
    state = refresh_state(old_state, 1)
    Click.create!(ip_address)
    PubSub.broadcast(
      PopKube.PubSub,
      topic(),
      {:count, get_count(state)}
    )
    handle_call_reply(state)
  end

  defp refresh_state(old_state), do: refresh_state(old_state, 0)
  defp refresh_state({count, last_db_sync}, change) do
    time_now = :os.system_time(:second)
    if (time_now - last_db_sync) > @db_sync_interval do
      {Click.count() + change, time_now}
    else
      {count + change, last_db_sync}
    end
  end

  defp get_count({count, _last_db_sync}), do: count

  defp handle_call_reply(state) do
    {:reply, get_count(state), state}
  end
end
