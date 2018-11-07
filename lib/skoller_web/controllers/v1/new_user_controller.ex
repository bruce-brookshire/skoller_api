defmodule SkollerWeb.Api.V1.NewUserController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Users
  alias SkollerWeb.AuthView

  def create(conn, params) do
    case Users.create_user(params, [login: true]) do
      {:ok, %{token: token} = user} ->
        render(conn, AuthView, "show.json", [user: user, token: token])
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
