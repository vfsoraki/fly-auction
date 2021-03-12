defmodule AuctionWeb.SearchLive do
  use AuctionWeb, :live_view
  alias Phoenix.PubSub
  alias Auction.PubSub, as: P
  alias Horde.Registry
  alias Auction.Registry, as: R

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket,
        id: nil,
        results: %{},
        pid: nil,
        name: nil,
        value: nil,
        won: false,
        state: nil,
        participants: []
     )
    }
  end

  @impl true
  def handle_event("suggest", %{"value" => v}, socket) do
    send(socket.assigns.pid, {:update, self(), v})

    {:noreply, assign(socket, value: v)}
  end

  @impl true
  def handle_event("search", %{"q" => id, "name" => n}, socket) do
    case search(id) do
      {:ok, pid, {state, desc}} ->
        send(pid, {:new, self(), n})

        socket =
          socket
          |> assign(id: id)
          |> assign(pid: pid)
          |> assign(desc: desc)
          |> assign(state: state)
          |> assign(name: n)
          |> put_flash(:info, "Auction found")

        PubSub.subscribe(P, id_to_key(id))

        {:noreply, socket}
      {:error, _} ->
        socket =
          socket
          |> assign(id: id)
          |> put_flash(:error, "Auction key not valid")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:participants, participants}, socket) do
    {:noreply, assign(socket, participants: participants)}
  end

  @impl true
  def handle_info({:winner, winner}, socket) do
    if winner == self() do
      {:noreply, assign(socket, won: true, state: :finished)}
    else
      {:noreply, assign(socket, won: false, state: :finished)}
    end
  end

  defp search(id) do
    case Registry.lookup(R, id_to_key(id)) do
      [{pid, value}] ->
        {:ok, pid, value}

      _others ->
        {:error, :not_found}
    end
  end

  defp id_to_key(id), do: "auction:#{id}"
end
