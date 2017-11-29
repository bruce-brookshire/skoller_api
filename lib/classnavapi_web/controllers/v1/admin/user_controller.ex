defmodule ClassnavapiWeb.Api.V1.Admin.UserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, _) do
    users = Repo.all(User)
    render(conn, UserView, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
      render(conn, UserView, "show.json", user: user)
  end

  def update(conn, %{"id" => id} = params) do
    user_old = Repo.get!(User, id)
    user_old = Repo.preload user_old, :student
    changeset = User.changeset_update(user_old, params)

    case Repo.update(changeset) do
      {:ok, user} ->
        render(conn, UserView, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
