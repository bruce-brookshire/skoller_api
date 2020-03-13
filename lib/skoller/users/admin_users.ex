defmodule Skoller.Admin.Users do
  @moduledoc """
  The Admin Users context.
  """

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.UserRoles.UserRole
  alias Skoller.Students.Student
  alias Skoller.EnrolledSchools

  import Ecto.Query

  @student_role "100"

  @doc """
  Returns a list of `Skoller.Users.User` and `Skoller.Students.Student` based on filters.

  ## Filters
    * or :boolean
      * when true, will or the filters.
    * account_type :id
      * Takes a `Skoller.Roles.Role` id
    * school_id :id
      * Requires account_type filter of student
      * Takes a `Skoller.Schools.School` id
    * user_name :string
      * Requires account_type filter of student
      * Searches first or last name of student
    * email :string
    * is_suspended :boolean

  ## Examples

      iex> Skoller.Admin.Users.get_users(%{})
      [{user: %Skoller.Users.User{}, student: %Skoller.Students.Student{}]

  """
  def get_users(params \\ %{}) do
    from(user in User)
    |> join(:left, [user], role in UserRole, on: role.user_id == user.id)
    |> join(:left, [user, role], student in Student, on: student.id == user.student_id)
    |> join(:left, [user, role, student], ss in subquery(EnrolledSchools.get_student_schools_subquery()), on: ss.student_id == student.id)
    |> where([user, role, student, ss], ^filters(params))
    |> distinct([user], user.id)
    |> select([user, role, student], %{user: user, student: student})
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :user, &1.user |> Repo.preload([:roles])))
  end
  
  @doc """
  Gets a user by id with `:roles`, `:student`, and `:reports` loaded.

  ## Returns
  `Skoller.Users.User` or `Ecto.NoResultsError`
  """
  def get_user_by_id!(id) do
    Repo.get!(User, id)
    |> Repo.preload([:roles, :student, :reports])
  end

  defp filters(params) when params == %{}, do: true
  defp filters(params) do
    dynamic = params["or"] != "true"

    dynamic
    |> name_filter(params)
    |> email_filter(params)
    |> account_type_filter(params)
    |> school_filter(params)
    |> suspended_filter(params)
  end

  defp account_type_filter(dynamic, %{"account_type" => filter}) do
    dynamic([user, role], role.role_id == ^filter and ^dynamic)
  end
  defp account_type_filter(dynamic, _params), do: dynamic

  defp school_filter(dynamic, %{"account_type" => @student_role, "school_id" => filter}) do
    dynamic([user, role, student, ss], ss.school_id == ^filter and ^dynamic)
  end
  defp school_filter(dynamic, _params), do: dynamic

  defp name_filter(dynamic, %{"account_type" => @student_role, "user_name" => filter, "or" => "true"}) do
    filter = "%" <> filter <> "%"
    dynamic([user, role, student], (ilike(student.name_first, ^filter) or ilike(student.name_last, ^filter)) or ^dynamic)
  end
  defp name_filter(dynamic, %{"account_type" => @student_role, "user_name" => filter}) do
    filter = "%" <> filter <> "%"
    dynamic([user, role, student], (ilike(student.name_first, ^filter) or ilike(student.name_last, ^filter)) and ^dynamic)
  end
  defp name_filter(dynamic, _params), do: dynamic

  defp email_filter(dynamic, %{"email" => filter, "or" => "true"}) do
    filter = "%" <> filter <> "%"
    dynamic([user], ilike(user.email, ^filter) or ^dynamic)
  end
  defp email_filter(dynamic, %{"email" => filter}) do
    filter = "%" <> filter <> "%"
    dynamic([user], ilike(user.email, ^filter) and ^dynamic)
  end
  defp email_filter(dynamic, _params), do: dynamic

  defp suspended_filter(dynamic, %{"is_suspended" => "true"}) do
    dynamic([user], user.is_active == false and ^dynamic)
  end
  defp suspended_filter(dynamic, %{"is_suspended" => "false"}) do
    dynamic([user], user.is_active == true and ^dynamic)
  end
  defp suspended_filter(dynamic, _params), do: dynamic

end