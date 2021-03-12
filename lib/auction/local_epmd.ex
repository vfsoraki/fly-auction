defmodule Auction.LocalEpmd do
  @moduledoc """
  A strategy to automatically connect all nodes
  connected to local epmd.

  Taken from https://github.com/bitwalker/libcluster/issues/124
  """
  use Cluster.Strategy

  alias Cluster.Strategy.State

  def start_link([%State{} = state]) do
    suffix = get_host_suffix(Node.self())

    {:ok, nodes} = :erl_epmd.names()
    nodes = for {n, _} <- nodes, do: List.to_atom(n ++ suffix)
    Cluster.Strategy.connect_nodes(state.topology, state.connect, state.list_nodes, nodes)
    :ignore
  end

  defp get_host_suffix(self) do
    self = Atom.to_charlist(self)
    [_, suffix] = :string.split(self, '@')
    '@' ++ suffix
  end
end
