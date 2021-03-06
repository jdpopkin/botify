defmodule Botify.Repo.Migrations.CreateCredentials do
  use Ecto.Migration

  def change do
    create table(:credentials) do
      add :access_token, :string
      add :refresh_token, :string
      timestamps()
    end
  end
end
