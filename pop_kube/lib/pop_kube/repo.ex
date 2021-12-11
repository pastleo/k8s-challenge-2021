defmodule PopKube.Repo do
  use Ecto.Repo,
    otp_app: :pop_kube,
    adapter: Ecto.Adapters.Postgres
end
