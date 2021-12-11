defmodule PopKube.Repo.Migrations.AddClicks do
  use Ecto.Migration

  def change do
    create table("clicks") do
      add :ip_address, :string

      timestamps()
    end
  end
end
