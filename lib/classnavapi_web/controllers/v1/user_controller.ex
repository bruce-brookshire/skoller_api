defmodule ClassnavapiWeb.Api.V1.UserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserView

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_user, :allow_admin

  def update(conn, %{"user_id" => id} = params) do
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
