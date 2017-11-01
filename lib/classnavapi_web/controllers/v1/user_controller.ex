defmodule ClassnavapiWeb.Api.V1.UserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.Repo
  alias ClassnavapiWeb.UserView

  defp insert_user(conn, changeset) do
    case Repo.insert(changeset) do
      {:ok, user} ->
        render(conn, UserView, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp school_accepting_enrollment(changeset, true), do: changeset
  defp school_accepting_enrollment(changeset, false), do: changeset |> Ecto.Changeset.add_error(:school_id, "School is not accepting enrollment.")

  def create(conn, %{"student" => student} = params) do
    school = Repo.get!(Classnavapi.School, student["school_id"])

    changeset = User.changeset_insert(%User{}, params)
    changeset = changeset |> school_accepting_enrollment(school.is_active_enrollment)

    conn
    |> insert_user(changeset)
  end

  def create(conn, %{} = params) do    
    changeset = User.changeset_insert(%User{}, params)

    conn
    |> insert_user(changeset)
  end

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