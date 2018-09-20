defmodule Skoller.Users do
  @moduledoc """
  The Users context.
  """

  alias Skoller.Repo
  alias Skoller.Users.User
  alias Skoller.UserRole
  alias Skoller.Students
  alias Skoller.Locks.Lock
  alias Skoller.Students.Student
  alias Skoller.Verification
  alias Skoller.CustomSignups
  alias Skoller.Users.Report
  alias Skoller.MapErrors
  alias Skoller.StudentPoints

  import Ecto.Query

  @student_role 100

  @student_referral_points_name "Student Referral"

  @doc """
  Gets student users.

  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_student_users() do
    from(u in User)
    |> where([u], not(is_nil(u.student_id)))
    |> Repo.all()
  end

  @doc """
  Reports a user

  ## Returns
  `{:ok, Skoller.Users.Report}` or `{:error, Ecto.Changeset}`
  """
  def report_user(params) do
    %Report{}
    |> Report.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Gets a user by id with `:roles` and `:student`

  ## Returns
  `Skoller.Users.User` or `Ecto.NoResultsError`
  """
  def get_user_by_id!(id) do
    Repo.get!(User, id)
    |> Repo.preload([:roles, :student])
  end

  @doc """
  Gets a user by id with `:roles` and `:student`

  ## Returns
  `Skoller.Users.User` or `nil`
  """
  def get_user_by_id(id) do
    Repo.get(User, id)
    |> Repo.preload([:roles, :student])
  end

  @doc """
  Creates a user, with student if included in `params`.

  ## Params
   * `%{"student" => %{"link" => enrollment_link}}`, will add enrolled_by to student based on the link.
   * `%{"student" => %{"custom_link" => custom_link}}`, will add student to custom link enrollment.

  ## Opts
   * `[admin: true]`, will verify without text.

  # Returns
  `{:ok, %{user: Skoller.Users.User, roles: [Skoller.UserRole], field_of_study: Skoller.Students.FieldOfStudy, custom_link: Skoller.CustomSignups.Signup || {:ok, nil}, link: String}}`
  or `{:error, failed_val}`
  """
  def create_user(params, opts \\ []) do
    multi = %User{}
    |> User.changeset_insert(params)
    |> verify_student(opts)
    |> verification_code(opts)
    |> get_enrolled_by(params)
    |> insert_user(params)
    |> Ecto.Multi.run(:custom_link, &custom_link_signup(&1.user, params))
    |> Ecto.Multi.run(:link, &get_link(&1.user))
    |> Ecto.Multi.run(:points, &add_points_to_student(&1.user))
    
    case multi |> Repo.transaction() do
      {:error, _, failed_val, _} ->
        {:error, failed_val}
      {:ok, items} ->
        {:ok, items}
    end
  end

  @doc """
  Updates a user, with student if included in params.

  # Returns
  `{:ok, %{user: Skoller.Users.User, roles: [Skoller.UserRole], field_of_study: Skoller.Students.FieldOfStudy, link: String}}`
  or `{:error, _, failed_val, _}`
  """
  def update_user(user_old, params) do
    changeset = User.changeset_update_admin(user_old, params)
    Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
    |> Ecto.Multi.run(:link, &get_link(&1.user))
    |> Repo.transaction()
  end

  @doc """
  Gets a user by email.

  ## Returns
  `Skoller.Users.User` or `nil`
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  @doc """
  Changes a user's password

  ## Returns
  `{:ok, Skoller.Users.User}` or `{:error, Ecto.Changeset}`
  """
  def change_password(user_old, password) do
    user_old
    |> User.changeset_update(%{"password" => password})
    |> Repo.update()
  end

  @doc """
  Gets the users enrolled in a class.
  
  ## Returns
  `[Skoller.Users.User]` or `[]`
  """
  def get_users_in_class(class_id) do
    from(u in User)
    |> join(:inner, [u], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.student_id == u.student_id)
    |> where([u, sc], sc.class_id == ^class_id)
    |> Repo.all()
  end

  @doc """
  Gets the locks by class.

  ## Returns
  `[%{lock: Skoller.Locks.Lock, user: Skoller.Users.User}]` or `[]`
  """
  def get_user_locks_by_class(class_id) do
    from(l in Lock)
    |> join(:inner, [l], u in User, l.user_id == u.id)
    |> where([l], l.class_id == ^class_id)
    |> select([l, u], %{lock: l, user: u})
    |> Repo.all()
  end

  defp add_points_to_student(%{student: %{enrolled_by: enrolled_by}}) when not(is_nil(enrolled_by)) do
    enrolled_by
    |> StudentPoints.add_points_to_student(@student_referral_points_name)
  end
  defp add_points_to_student(_student_class), do: {:ok, nil}

  # Generates a verification code if admin: true is not passed in through opts.
  defp verification_code(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset, opts) do
    case get_opt(opts, :admin) do
      "true" -> 
        u_changeset
      _ ->
        Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :verification_code, Verification.generate_verify_code)})
    end
  end
  defp verification_code(changeset, _opts), do: changeset

  # Verifies a student if admin: true passed in though opts.
  defp verify_student(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset, opts) do
    case get_opt(opts, :admin) do
      "true" -> 
        Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :is_verified, true)})
      _ -> 
        u_changeset
    end
  end
  defp verify_student(changeset, _opts), do: changeset

  # Adds enrolled_by if "link" is present in params.
  defp get_enrolled_by(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset, %{"student" => %{"link" => link}}) do
    enrolled_by = Repo.get_by(Student, enrollment_link: link)
    case enrolled_by do
      nil -> u_changeset
      enrolled_by -> Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :enrolled_by, enrolled_by.id)})
    end
  end
  # Adds enrolled_by if "enrollment_link" is present in params.
  defp get_enrolled_by(%Ecto.Changeset{valid?: true, changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}} = u_changeset, %{"student" => %{"enrollment_link" => link}}) do
    enrolled_by = Students.get_student_class_by_enrollment_link(link)
    case enrolled_by do
      nil -> u_changeset
      enrolled_by -> Ecto.Changeset.change(u_changeset, %{student: Map.put(s_changeset.changes, :enrolled_by, enrolled_by.student.id)})
    end
  end
  defp get_enrolled_by(changeset, _params), do: changeset

  # The standard insert user multi.
  defp insert_user(changeset, params) do
    Ecto.Multi.new
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:roles, &add_roles(&1, params))
    |> Ecto.Multi.run(:fields_of_study, &add_fields_of_study(&1, params))
  end

  # Gets a link for a student.
  defp get_link(%User{student: %Student{} = student}) do
    Students.generate_student_link(student)
  end
  defp get_link(_user), do: {:ok, nil}

  # Adds student to custom link enrollment if the custom link exists.
  defp custom_link_signup(%User{student: %Student{} = student}, %{"student" => %{"custom_link" => link}}) do
    case CustomSignups.get_link_by_link(link) do
      nil -> {:ok, nil}
      link -> CustomSignups.track_signup(student.id, link.id)
    end
  end
  defp custom_link_signup(_user, _params), do: {:ok, nil}

  defp add_fields_of_study(_map, %{"student" => %{"fields_of_study" => nil}}), do: {:ok, nil}
  defp add_fields_of_study(%{user: user}, %{"student" => %{"fields_of_study" => fields}}) do
    delete_fields_of_study(user.student.id)
    status = fields |> Enum.map(&add_field_of_study(user, &1))

    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
  defp add_fields_of_study(_map, _params), do: {:ok, nil}

  defp add_field_of_study(user, field) do
    params = %{field_of_study_id: field, student_id: user.student.id}
    Students.add_field_of_study(params)
  end

  defp add_roles(%{user: user}, params) do
    user 
    |> Repo.preload(:student)
    |> add_roles_preloaded(params)
  end

  defp add_roles_preloaded(%{student: student} = user, _params) when not is_nil(student) do
    user = user |> Repo.preload(:roles)
    case user.roles |> Enum.any?(& &1.id == @student_role) do
      false -> Repo.insert(%UserRole{user_id: user.id, role_id: @student_role})
      true -> {:ok, nil}
    end
  end
  defp add_roles_preloaded(user, %{"roles" => roles}) do
    delete_roles(user.id)
    status = roles
    |> Enum.map(&add_role(user, &1))
    
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
  defp add_roles_preloaded(_map, _params), do: {:ok, nil}

  defp add_role(user, role) do
    Repo.insert!(%UserRole{user_id: user.id, role_id: role})
  end

  defp delete_roles(id) do
    from(role in UserRole)
    |> where([role], role.user_id == ^id)
    |> Repo.delete_all()
  end

  defp delete_fields_of_study(id) do
    Students.delete_fields_of_study_by_student_id(id)
  end

  # Parses a keylist and gets the value of the atom.
  defp get_opt(opts, atom) do
    case opts |> List.keytake(atom, 0) do
      nil -> nil
      val -> val |> elem(0) |> elem(1)
    end
  end
end