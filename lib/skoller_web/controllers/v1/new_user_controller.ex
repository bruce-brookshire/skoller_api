defmodule SkollerWeb.Api.V1.NewUserController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Users
  alias Skoller.Users.User
  alias SkollerWeb.UserView

  def create(conn, params) do
    case Users.create_user(params) do
      {:ok, %User{} = user} ->
        render(conn, UserView, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
