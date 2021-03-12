defmodule AuctionWeb.SearchLive do
  use AuctionWeb, :live_view
  alias Phoenix.PubSub
  alias Auction.PubSub, as: P

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(q: nil)
      |> assign(result: [])

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    PubSub.broadcast(P, "auctions", {:match, self(), q})
    {:noreply, assign(socket, result: [])}
  end

  @impl true
  def handle_info({:match, id, desc, parts_count}, socket) do
    IO.inspect({id, desc, parts_count})
    result = [{id, desc, parts_count} | socket.assigns.result]
    {:noreply, assign(socket, result: result)}
  end
end
