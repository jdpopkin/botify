defmodule Botify.Credentials do
  use Botify.Web, :model

  schema "credentials" do
    field :access_token, :string
    field :refresh_token, :string
    timestamps()
  end
end
