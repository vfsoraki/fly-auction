# Auction

A sample application built using Elixir and LiveView.

This is an auction application. One person creates and auction,
and other people can participate in it. Creator can end the auction
anytime, announcing the highest bidder winner.

This application is designed for a test-run environment, to study the
code and (hopefully) learning something from it. It does not contain
configuration for production or release, and also does not use databases.
Everything is removed when nodes restart.

To start:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start a node with `PORT=4000 iex --name node1 -S mix phx.server`

`PORT` is optional and defaults to `4000`, but you need to change it when
starting another node on your machine.
You can start another node with `PORT=4001 iex --name node1 -S mix phx.server`,
and point your browser to either `localhost:4000` or `localhost:4001` and see
the end result.
