defmodule SkollerWeb.Api.V1.NewUserController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Users
  alias SkollerWeb.AuthView
  alias Skoller.Token
  alias SkollerWeb.Responses.MultiError

  def create(conn, params) do
    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:user, &create_user(params, &1))
    |> Ecto.Multi.run(:token, &Token.login(&1.user.id))
    |> Repo.transaction()

    case multi do
      {:ok, %{user: user, token: token}} ->
        render(conn, AuthView, "show.json", [user: user, token: token])
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  defp create_user(params, _) do
    Users.create_user(params)
  end
end
