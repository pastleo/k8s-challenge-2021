defmodule PopKubeWeb.Counter do
  use Phoenix.LiveView
  alias PopKube.Count
  alias Phoenix.PubSub
  alias PopKube.Presence
  alias PopKubeWeb.Router.Helpers, as: Routes

  @topic Count.topic
  @presence_topic "presence"

  def mount(_params, session, socket) do
    PubSub.subscribe(PopKube.PubSub, @topic)

    Presence.track(self(), @presence_topic, socket.id, %{})
    PopKubeWeb.Endpoint.subscribe(@presence_topic)

    initial_present =
      Presence.list(@presence_topic)
      |> map_size

    {:ok, assign(
      socket,
      val: Count.current(), present: initial_present,
      ip_address: Map.get(session, "ip_address")
    ) }
  end

  def handle_event("add_click", _, socket) do
    added = Count.add_click(socket.assigns.ip_address)
    {:noreply, assign(socket, :val, added)}
  end

  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, val: count)}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{present: present}} = socket
      ) do
    new_present = present + map_size(joins) - map_size(leaves)

    {:noreply, assign(socket, :present, new_present)}
  end

  def render(assigns) do
    ~L"""
    <div id="pop-clicker">
      <h1 class="count"><%= @val %></h1>
      <img
        phx-click="add_click"
        src="<%= Routes.static_path(@socket, "/images/kube.svg") %>"
        alt="PopKube"
      />
      <h1>Users Online: <%= @present %></h1>
    </div>
    """
  end
end
