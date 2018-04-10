defmodule SkollerWeb.Api.V1.UserController do
  use SkollerWeb, :controller

  alias Skoller.Users.User
  alias Skoller.Repo
  alias SkollerWeb.UserView
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.UserRole
  alias Skoller.PicUpload
  alias Skoller.School.StudentField
  alias Ecto.UUID
  alias Skoller.Users

  import SkollerWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_user, :allow_admin

  def update(conn, %{"user_id" => id} = params) do
    user_old = Repo.get!(User, id)
    user_old = Repo.preload user_old, :student
    location = params |> upload_pic()

    params = params |> Map.put("pic_path", location)
    |> Map.put("student", params["student"] |> Users.put_future_reminder_notification_time())
    changeset = User.changeset_update(user_old, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:roles, &check_student_role(changeset, &1))
    |> Ecto.Multi.run(:delete_fields_of_study, &delete_fields_of_study(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))

    case Repo.transaction(multi) do
      {:ok, %{user: user}} ->
        render(conn, UserView, "show.json", user: user)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp upload_pic(%{"file" => file}) do
    scope = %{"id" => UUID.generate()} 
    case PicUpload.store({file, scope}) do
      {:ok, inserted} ->
        PicUpload.url({inserted, scope}, :thumb)
      _ ->
        nil
    end
  end
  defp upload_pic(_params), do: nil

  defp delete_fields_of_study(%{user: %{student: nil}}, _params), do: {:ok, nil}
  defp delete_fields_of_study(%{user: %{student: _student}}, %{"student" => %{"fields_of_study" => nil}}), do: {:ok, nil}
  defp delete_fields_of_study(%{user: %{student: student}}, %{"student" => %{"fields_of_study" => _fields}}) do
    from(sf in StudentField)
    |> where([sf], sf.student_id == ^student.id)
    |> Repo.delete_all()
    {:ok, nil}
  end
  defp delete_fields_of_study(%{user: %{student: _student}}, _params), do: {:ok, nil}

  defp add_fields_of_study(%{user: user}, %{"student" => %{"fields_of_study" => fields}}) do
    status = fields |> Enum.map(&add_field_of_study(user, &1))

    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp add_fields_of_study(_map, _params), do: {:ok, nil}

  defp add_field_of_study(user, field) do
    Repo.insert!(%StudentField{field_of_study_id: field, student_id: user.student.id})
  end

  defp check_student_role(%Ecto.Changeset{changes: %{student: %Ecto.Changeset{action: :insert}}}, %{user: user}) do
    Repo.insert(%UserRole{user_id: user.id, role_id: @student_role})
  end
  defp check_student_role(_changeset, _user), do: {:ok, nil}
end
