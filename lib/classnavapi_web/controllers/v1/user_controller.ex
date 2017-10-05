defmodule ClassnavapiWeb.Api.V1.UserController do
  use ClassnavapiWeb, :controller

  def create(conn, params = %{}) do

    changeset = Classnavapi.User.changeset(%Classnavapi.User{}, params)

    case Classnavapi.Repo.insert(changeset) do
      {:ok, user} ->
        render(conn, ClassnavapiWeb.UserView, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, _) do
    users = Classnavapi.Repo.all(Classnavapi.User)
    render(conn, ClassnavapiWeb.UserView, "index.json", users: users)
  end
end