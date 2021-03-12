# Auction

**NOTE**: This is not yet finished, but feel free to explore.

A sample application built using Elixir and LiveView.

This is an auction application. One person creates an auction,
and other people can participate in it. Creator can end the auction
anytime, announcing the highest bidder winner.

This application is designed for a test-run environment, to study the
code. It does contain configuration for a release, but it is not well-thought.
Also does not use databases, everything is removed when nodes restart.

To start:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start a node with `PORT=4000 iex --name node1 -S mix phx.server`

`PORT` is optional and defaults to `4000`, but you need to change it when
starting another node on your machine.
You can start another node with `PORT=4001 iex --name node1 -S mix phx.server`,
and point your browser to either `localhost:4000` or `localhost:4001` and see
the end result. This application uses [libcluster](https://github.com/bitwalker/libcluster/)
to automatically connect nodes in both dev and prod environments.

Also, `Dockerfile` and `fly.toml` files are provided for deployment to fly.io. to
deploy:

  * Install `docker`: https://docker.io
  * Install `flyctl`: https://fly.io/docs/getting-started/installing-flyctl/
  * Run `flyctl auth signup` or (if you're already signed up) `flyctl auth login`
  * Run `flyctl init` and choose `none` as builder, as we're using a Docker image
  * Run `flyctl deploy` and go to your app's url
