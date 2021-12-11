defmodule PopKube.Click do
  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  alias PopKube.Click
  alias PopKube.Repo

  schema "clicks" do
    field :ip_address, :string

    timestamps()
  end

  def create!(ip_address) do
    %Click{
      ip_address: ip_address
    }
    |> Repo.insert!()
  end

  def count() do
    from(c in Click, select: count(c.id))
    |> Repo.one()
  end
end
