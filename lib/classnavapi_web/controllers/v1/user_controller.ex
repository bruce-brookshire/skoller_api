defmodule ClassnavapiWeb.Api.V1.UserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserView

  def create(conn, params = %{}) do

    changeset = User.changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        render(conn, UserView, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _) do
    users = Repo.all(User)
    render(conn, UserView, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
      render(conn, UserView, "show.json", user: user)
  end
end