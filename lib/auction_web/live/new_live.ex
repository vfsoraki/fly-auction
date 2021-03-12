defmodule AuctionWeb.NewLive do
  use AuctionWeb, :live_view
  alias Phoenix.PubSub
  alias Auction.PubSub, as: P
  alias Horde.Registry
  alias Auction.Registry, as: R

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       id: random_id(),
       desc: "",
       # can be ready, live, finished
       state: :ready,
       winner: nil,
       participants: []
     )}
  end

  @impl true
  def handle_event("create", %{"desc" => desc}, socket) do
    if socket.assigns.state == :ready do
      Registry.register(R, id_to_key(socket.assigns.id), {:live, desc})
      {:noreply, assign(socket, started: true, desc: desc, state: :live)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("finish", _, socket) do
    if socket.assigns.state == :live do
      [{winner, _, _} | _] = sort_participants(socket.assigns.participants)

      # For those who are connected now
      PubSub.broadcast(
        P,
        id_to_key(socket.assigns.id),
        {:winner, winner}
      )

      # For those who might connect late
      Registry.update_value(R, id_to_key(socket.assigns.id), fn {_, desc} -> {:finished, desc} end)

      socket =
        socket
        |> assign(winner: winner)
        |> assign(state: :finished)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new, pid, name}, socket) do
    if socket.assigns.state == :live do
      participants =
        [{pid, name, "0"} | socket.assigns.participants]
        |> sort_participants()

      PubSub.broadcast(
        P,
        id_to_key(socket.assigns.id),
        {:participants, participants}
      )

      {:noreply, assign(socket, participants: participants)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:update, pid, value}, socket) do
    if socket.assigns.state == :live do
      participants =
        socket.assigns.participants
        |> Enum.map(fn
          {^pid, name, _old_value} -> {pid, name, value}
          {_, _, _} = others -> others
        end)
        |> sort_participants()

      PubSub.broadcast(
        P,
        id_to_key(socket.assigns.id),
        {:participants, participants}
      )

      {:noreply, assign(socket, participants: participants)}
    else
      {:noreply, socket}
    end
  end

  defp id_to_key(id), do: "auction:#{id}"

  def sort_participants(p) do
    Enum.sort_by(
      p,
      fn {_, _, v} -> v |> Float.parse() |> elem(0) end,
      &>=/2
    )
  end

  def random_id(length \\ 10) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
