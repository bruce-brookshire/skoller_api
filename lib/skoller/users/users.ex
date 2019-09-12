defmodule Skoller.Users do
  @moduledoc """
  The Users context.
  """

  alias Skoller.Repo
  alias Skoller.Users
  alias Skoller.Users.User
  alias Skoller.Students
  alias Skoller.Students.Student
  alias Skoller.CustomSignups
  alias Skoller.MapErrors
  alias Skoller.StudentPoints
  alias Skoller.Users.Notifications
  alias Skoller.StudentClasses.EnrollmentLinks
  alias Skoller.UserRoles
  alias Skoller.Students.Sms
  alias Skoller.Token
  alias Skoller.Users.Emails
  alias Skoller.Students.Organizations
  alias Skoller.Devices.Device

  import Ecto.Query

  @student_role 100

  @student_referral_points_name "Student Referral"

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
  Gets a user by student_id with `:roles` and `:student`

  ## Returns
  `Skoller.Users.User` or `nil`
  """
  def get_user_by_student_id(student_id) do
    Repo.get_by(User, student_id: student_id)
    |> Repo.preload([:roles, :student])
  end

  @doc """
  Creates a user, with student if included in `params`.

  ## Params
   * `%{"student" => %{"link" => enrollment_link}}`, will add enrolled_by to student based on the link.
   * `%{"student" => %{"custom_link" => custom_link}}`, will add student to custom link enrollment.

  ## Opts
   * `[admin: true]`, will verify without text.
   * `[login: true]` will send a token with the response.

  # Returns
  `{:ok, Skoller.Users.User}` or `{:error, changeset}`
  """
  def create_user(params, opts \\ []) do
    result =
      %User{}
      |> User.changeset_insert(params)
      |> verification_code(opts)
      |> get_enrolled_by(params)
      |> insert_user(params, opts)
      |> Ecto.Multi.run(:custom_link, fn _, changes ->
        custom_link_signup(changes.user, params)
      end)
      |> Ecto.Multi.run(:link, fn _, changes -> get_link(changes.user) end)
      |> Ecto.Multi.run(:points, fn _, changes -> add_points_to_student(changes.user) end)
      |> Repo.transaction()
      |> send_link_used_notification()
      |> send_verification_text()

    case result do
      {:ok, %{user: user}} ->
        user =
          user
          |> Users.preload_student([], force: true)
          |> Repo.preload([:reports], force: true)
          |> Repo.preload([:roles], force: true)

        {:ok, user}

      {:error, _, failed_val, _} ->
        IO.puts("ATTENTION SIGNUP 404:")
        IO.inspect(failed_val)
        {:error, failed_val}
    end
  end

  @doc """
  Updates a user, with student if included in params.

  ## Opts
   * `[admin: true]`, will allow admin changes.
   * `[admin_update: true]`, will allow admin only changes.

  # Returns
  `{:ok, %{user: Skoller.Users.User, roles: [Skoller.UserRoles.UserRole], field_of_study: Skoller.Students.FieldOfStudy, link: String}}`
  or `{:error, _, failed_val, _}`
  """
  def update_user(user_old, params, opts \\ []) do
    changeset =
      if(Keyword.get(opts, :admin_update, false),
        do: User.changeset_update_admin(user_old, params),
        else: User.changeset_update(user_old, params)
      )

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:roles, fn _, changes -> add_roles(changes, params, opts) end)
    |> Ecto.Multi.run(:fields_of_study, fn _, changes -> add_fields_of_study(changes, params) end)
    |> Ecto.Multi.run(:link, fn _, changes -> get_link(changes.user) end)
    |> Repo.transaction()
  end

  def delete_user(user_id) do
    user = Repo.get(User, user_id) |> Repo.preload([:student], force: false)

    if user == nil do
      {:error, 404}
    else
      user_device_query =
        from(d in Device)
        |> where([d], d.user_id == ^user_id)

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.delete_all(:user_devices, user_device_query)
        |> Ecto.Multi.delete(:users, user)

      if user.student_id != nil do
        # Delete student (will cascade to student_class and student_assignment)
        multi
        |> Ecto.Multi.delete(:students, user.student)
        |> Repo.transaction()
      else
        # Delete just user
        multi
        |> Repo.transaction()
      end
    end
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
    Ecto.Multi.new()
    |> Ecto.Multi.run(:user, fn _, changes -> change_password(user_old, password, changes) end)
    |> Ecto.Multi.run(:token, fn _, changes -> Token.login(changes.user.id) end)
    |> Repo.transaction()
  end

  def forgot_password(email) do
    case get_user_by_email(email) do
      nil ->
        nil

      user ->
        {:ok, token} = user.id |> Token.short_token()
        user |> Emails.send_forgot_pass_email(token)
    end
  end

  defp change_password(user_old, password, _) do
    user_old
    |> User.changeset_update(%{"password" => password})
    |> Repo.update()
  end

  defp send_link_used_notification(
         {:ok, %{user: %{student: %{enrolled_by: student_id}}}} = result
       )
       when not is_nil(student_id) do
    Task.start(Notifications, :send_link_used_notification, [student_id])
    result
  end

  defp send_link_used_notification(result), do: result

  defp send_verification_text(
         {:ok, %{user: %{student: %{phone: phone, verification_code: verification_code}}}} =
           result
       ) do
    phone |> Sms.verify_phone(verification_code)
    result
  end

  defp send_verification_text(result), do: result

  defp add_points_to_student(%{student: %{enrolled_by: enrolled_by}})
       when not is_nil(enrolled_by) do
    enrolled_by
    |> StudentPoints.add_points_to_student(@student_referral_points_name)
  end

  defp add_points_to_student(_student_class), do: {:ok, nil}

  # Generates a verification code if admin: true is not passed in through opts.
  defp verification_code(
         %Ecto.Changeset{
           valid?: true,
           changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}
         } = u_changeset,
         opts
       ) do
    case Keyword.get(opts, :admin, false) do
      true ->
        u_changeset

      _ ->
        Ecto.Changeset.change(u_changeset, %{
          student:
            s_changeset.changes
            |> Map.put(:verification_code, Students.generate_verify_code())
            |> Map.put(:login_attempt, DateTime.utc_now() |> DateTime.truncate(:second))
        })
    end
  end

  defp verification_code(changeset, _opts), do: changeset

  # Adds enrolled_by if "link" is present in params.
  defp get_enrolled_by(
         %Ecto.Changeset{
           valid?: true,
           changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}
         } = u_changeset,
         %{"student" => %{"link" => link}}
       ) do
    enrolled_by = Repo.get_by(Student, enrollment_link: link)

    case enrolled_by do
      nil ->
        u_changeset

      enrolled_by ->
        Ecto.Changeset.change(u_changeset, %{
          student: Map.put(s_changeset.changes, :enrolled_by, enrolled_by.id)
        })
    end
  end

  # Adds enrolled_by if "enrollment_link" is present in params.
  defp get_enrolled_by(
         %Ecto.Changeset{
           valid?: true,
           changes: %{student: %Ecto.Changeset{valid?: true} = s_changeset}
         } = u_changeset,
         %{"student" => %{"enrollment_link" => link}}
       ) do
    enrolled_by = EnrollmentLinks.get_student_class_by_enrollment_link(link)

    case enrolled_by do
      nil ->
        u_changeset

      enrolled_by ->
        Ecto.Changeset.change(u_changeset, %{
          student: Map.put(s_changeset.changes, :enrolled_by, enrolled_by.student.id)
        })
    end
  end

  defp get_enrolled_by(changeset, _params), do: changeset

  # The standard insert user multi.
  defp insert_user(changeset, params, opts) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:roles, fn _, changes -> add_roles(changes, params, opts) end)
    |> Ecto.Multi.run(:fields_of_study, fn _, changes -> add_fields_of_study(changes, params) end)
  end

  # Gets a link for a student.
  defp get_link(%User{student: %Student{} = student}) do
    Students.generate_student_link(student)
  end

  defp get_link(_user), do: {:ok, nil}

  # Adds student to custom link enrollment if the custom link exists.
  defp custom_link_signup(%User{student: %Student{} = student}, %{
         "student" => %{"custom_link" => link}
       }) do
    case CustomSignups.get_link_by_link(link) do
      nil -> {:ok, nil}
      link -> CustomSignups.track_signup(student.id, link.id)
    end
  end

  # Adds student to custom link enrollment if the user referring the student is attached to an organization with a link.
  defp custom_link_signup(%User{student: %Student{enrolled_by: enrolled_by} = student}, _params)
       when not is_nil(enrolled_by) do
    Organizations.attribute_signup_to_organization(student.id, enrolled_by)
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

  defp add_roles(%{user: user}, params, opts) do
    user
    |> Repo.preload(:student)
    |> add_roles_preloaded(params, opts)
  end

  defp add_roles_preloaded(%{student: student} = user, _params, _opts) when not is_nil(student) do
    user = user |> Repo.preload(:roles)

    case user.roles |> Enum.any?(&(&1.id == @student_role)) do
      false -> UserRoles.add_role(user.id, @student_role)
      true -> {:ok, nil}
    end
  end

  defp add_roles_preloaded(user, %{"roles" => roles}, opts) do
    case Keyword.get(opts, :admin, false) do
      true ->
        # Admin can add roles
        UserRoles.delete_roles_for_user(user.id)

        status =
          roles
          |> Enum.map(&UserRoles.add_role(user.id, &1))

        status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))

      false ->
        # Otherwise no.
        changeset =
          user
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.add_error(:roles, "Insufficient permissions")

        {:error, changeset}
    end
  end

  defp add_roles_preloaded(_map, _params, _opts), do: {:ok, nil}

  defp delete_fields_of_study(id) do
    Students.delete_fields_of_study_by_student_id(id)
  end

  def preload_student(user, student_preloads \\ [], opts \\ []) do
    user |> Repo.preload([{:student, student_preloads}], opts)
  end
end
