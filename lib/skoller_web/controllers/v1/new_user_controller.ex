defmodule SkollerWeb.Api.V1.NewUserController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Users
  alias Skoller.Users.User
  alias SkollerWeb.UserView

  def create(conn, params) do
    case Users.create_user(params) do
      {:ok, %User{} = user} ->
        conn
        |> put_view(UserView)
        |> render("show.json", user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
