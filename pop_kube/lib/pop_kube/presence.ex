defmodule PopKube.Presence do
  use Phoenix.Presence,
    otp_app: :live_view_counter,
    pubsub_server: PopKube.PubSub
end
