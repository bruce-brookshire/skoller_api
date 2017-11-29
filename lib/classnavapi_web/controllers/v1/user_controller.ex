defmodule ClassnavapiWeb.Api.V1.UserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.UserRole
  alias Classnavapi.Repo
  alias ClassnavapiWeb.AuthView
  alias Ecto.Changeset
  alias ClassnavapiWeb.Helpers.TokenHelper
  alias ClassnavapiWeb.Helpers.RepoHelper

  @student_role 100

  def create(conn, %{"student" => student} = params) do
    school = Repo.get(Classnavapi.School, student["school_id"])

    changeset = User.changeset_insert(%User{}, params)
    changeset = changeset |> school_accepting_enrollment(school)

    multi = changeset
    |> insert_user()
    |> Ecto.Multi.run(:role, &add_student_role(&1))
    |> user_transaction(conn)
  end

  def create(conn, %{} = params) do
    changeset = User.changeset_insert(%User{}, params)

    multi = changeset
    |> insert_user()
    |> user_transaction(conn)
  end

  defp insert_user(changeset) do
    Ecto.Multi.new
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:token, &TokenHelper.login(&1))
  end

  defp user_transaction(multi, conn) do
    case Repo.transaction(multi) do
      {:ok, %{} = auth} ->
        render(conn, AuthView, "show.json", auth: auth)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp add_student_role(%{user: user}) do
    Repo.insert(%UserRole{user_id: user.id, role_id: @student_role})
  end

  defp school_enrolling(changeset, true), do: changeset
  defp school_enrolling(changeset, false), do: changeset |> Changeset.add_error(:student, "School not accepting enrollment.")

  defp school_accepting_enrollment(changeset, nil), do: changeset
  defp school_accepting_enrollment(changeset, school) do
    changeset
    |> school_enrolling(school.is_active_enrollment)
  end
end
