# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :botify,
  ecto_repos: [Botify.Repo]

# Configures the endpoint
config :botify, Botify.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JQ/2EstzC5Cbm1CX5df2Sa0VB3gBdenWT0OjvTwCsCiyaMAMFZNp2zcaxKiDf6Jv",
  render_errors: [view: Botify.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Botify.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures Spotify
config :spotify_ex, scopes: ["playlist-modify-public"],
                    callback_url: System.get_env("APP_URL") <> "/callback",
                    client_id: System.get_env("SPOTIFY_ID"),
                    secret_key: System.get_env("SPOTIFY_SECRET")


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
