defmodule ClassnavapiWeb.Api.V1.NewUserController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Users.User
  alias Classnavapi.UserRole
  alias Classnavapi.Repo
  alias Classnavapi.School.StudentField
  alias ClassnavapiWeb.AuthView
  alias Ecto.Changeset
  alias ClassnavapiWeb.Helpers.TokenHelper
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.VerificationHelper
  alias ClassnavapiWeb.Sms
  alias Classnavapi.Users
  alias Classnavapi.Schools.School

  @student_role 100

  def create(conn, %{"student" => student} = params) do
    params = params |> Map.put("student", student |> Users.put_future_reminder_notification_time())

    changeset = User.changeset_insert(%User{}, params)
    changeset = changeset 
                |> verification_code()

    multi = changeset
    |> insert_user()
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
    |> Ecto.Multi.run(:role, &add_student_role(&1))
    
    case Repo.transaction(multi) do
      {:ok, %{user: user} = auth} ->
        user.student.phone |> Sms.verify_phone(user.student.verification_code)
        render(conn, AuthView, "show.json", auth: auth)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def create(conn, %{} = params) do
    changeset = User.changeset_insert(%User{}, params)

    multi = changeset |> insert_user()
    
    case Repo.transaction(multi) do
      {:ok, %{} = auth} ->
        render(conn, AuthView, "show.json", auth: auth)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp add_fields_of_study(%{user: user}, %{"student" => %{"fields_of_study" => fields}}) do
    status = fields |> Enum.map(&add_field_of_study(user, &1))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp add_fields_of_study(_map, _params), do: {:ok, nil}

  defp add_field_of_study(user, field) do
    Repo.insert!(%StudentField{field_of_study_id: field, student_id: user.student.id})
  end

  defp insert_user(changeset) do
    Ecto.Multi.new
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:token, &TokenHelper.login(&1))
  end

  defp add_student_role(%{user: user}) do
    Repo.insert(%UserRole{user_id: user.id, role_id: @student_role})
  end

  defp verification_code(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset) do
    Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :verification_code, VerificationHelper.generate_verify_code)})
  end
  defp verification_code(changeset), do: changeset
end
