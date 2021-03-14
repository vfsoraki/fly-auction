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
       id: if(connected?(socket), do: random_id(), else: nil),
       desc: "",
       # can be ready, live, finished
       state: :ready,
       winner: nil,
       participants: [],
       monitors: %{}
     )}
  end

  @impl true
  def handle_event("create", %{"desc" => desc}, socket) do
    if socket.assigns.state == :ready do
      # For direct connection
      Registry.register(R, id_to_key(socket.assigns.id), {:live, desc})
      # For search
      PubSub.subscribe(P, "auctions")
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
      # Add this new participant
      participants =
        [{pid, name, "0"} | socket.assigns.participants]
        |> sort_participants()

      # Tell everybody we have a new participant
      PubSub.broadcast(
        P,
        id_to_key(socket.assigns.id),
        {:participants, participants}
      )

      # Monitor participant, in case they leave
      ref = :erlang.monitor(:process, pid)
      monitors = Map.put(socket.assigns.monitors, ref, pid)

      {:noreply, assign(socket, participants: participants, monitors: monitors)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {:DOWN, ref, :process, _pid, _},
        %{assigns: %{monitors: monitors, participants: participants}} = socket
      ) do
    # Remove them from participants
    {pid, monitors} = Map.pop(monitors, ref)

    participants =
      participants
      |> Enum.filter(fn
        {^pid, _, _} -> false
        _ -> true
      end)
      |> sort_participants()

    # Tell everybody participant has left
    PubSub.broadcast(
      P,
      id_to_key(socket.assigns.id),
      {:participants, participants}
    )

    socket =
      socket
      |> assign(monitors: monitors)
      |> assign(participants: participants)

    {:noreply, socket}
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

  @impl true
  def handle_info({:match, pid, q}, socket) do
    IO.inspect({pid, q})

    desc = String.downcase(socket.assigns.desc)
    q = String.downcase(q)

    if String.contains?(desc, q) do
      send(pid, {
        :match,
        socket.assigns.id,
        socket.assigns.desc,
        length(socket.assigns.participants)
      })
    end

    {:noreply, socket}
  end

  defp id_to_key(id), do: "auction:#{id}"

  def sort_participants(p) do
    Enum.sort_by(
      p,
      fn {_, _, v} ->
        case Float.parse(v) do
          :error -> 0
          {float, _r} -> float
        end
      end,
      &>=/2
    )
  end

  def random_id(length \\ 10) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
