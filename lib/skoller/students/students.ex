defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """

  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Students.FieldOfStudy, as: StudentField
  alias Skoller.StudentClasses.EnrollmentLinks
  alias Skoller.Students.Sms
  alias Skoller.StudentPoints.StudentPoint
  alias Skoller.CustomSignups.Signup
  alias Skoller.Organizations.Organization

  import Ecto.Query

  use Timex

  require Logger

  @doc """
  Gets a student by id.

  ## Returns
  `Skoller.Students.Student` or `Ecto.NoResultsError`
  """
  def get_student_by_id!(student_id) do
    Repo.get!(Student, student_id)
  end

  def get_student_by_enrollment_link!(link) do
    Repo.get_by!(Student, enrollment_link: link)
  end

  @doc """
  Gets a student by phone.

  ## Returns
  `Skoller.Students.Student` or `nil`
  """
  def get_student_by_phone(phone) do
    from(s in Student)
    |> where([s], s.phone == ^phone)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Adds a field of study to a student.

  ## Returns
  `{:ok, Skoller.Students.FieldOfStudy}` with `:student` loaded or `{:error, Ecto.Changeset}`
  """
  def add_field_of_study(params) do
    changeset = StudentField.changeset(%StudentField{}, params)

    case changeset |> Repo.insert() do
      {:ok, results} -> results |> Repo.preload(:student)
      error -> error
    end
  end

  @doc """
  Gets a student field of study by student id and field id.

  ## Returns
  `{:ok, Skoller.Students.FieldOfStudy}` or `Ecto.NoResultsError`
  """
  def get_field_of_study_by_id!(student_id, field_of_study_id) do
    Repo.get_by!(StudentField, student_id: student_id, field_of_study_id: field_of_study_id)
  end

  @doc """
  Deletes a student field of study.

  ## Returns
  `{:ok, Skoller.Students.FieldOfStudy}` or `{:error, Ecto.Changeset}`
  """
  def delete_field_of_study(field) do
    Repo.delete(field)
  end

  @doc """
  Deletes all student fields of study by student.
  """
  def delete_fields_of_study_by_student_id(student_id) do
    from(sf in StudentField)
    |> where([sf], sf.student_id == ^student_id)
    |> Repo.delete_all()
  end

  @doc """
  Generates an enrollment link for a student that does not have one yet.

  ## Returns
  `{:ok, Skoller.Students.Student}` or `{:error, Ecto.Changeset}` or `{:ok, nil}` if there is already a link.
  """
  def generate_student_link(%Student{id: id, enrollment_link: nil} = student) do
    link = EnrollmentLinks.generate_link(id)

    student
    |> Ecto.Changeset.change(%{enrollment_link: link})
    |> Repo.update()
  end

  def generate_student_link(_student), do: {:ok, nil}

  @doc """
  Generates a 5 digit verification code.

  ## Returns
  `String`
  """
  def generate_verify_code() do
    case :rand.uniform() do
      0.0 -> generate_verify_code()
      num -> num |> convert_rand() |> to_string()
    end
  end

  @doc """
  Resets the verify code on the `student` and sends a text with the new code.

  ## Returns
  `{:ok, student}` or `{:error, changeset}`
  """
  def reset_verify_code(student) do
    code = generate_verify_code()

    result =
      student
      |> Ecto.Changeset.change(%{verification_code: code})
      |> Repo.update()

    case result do
      {:ok, student} ->
        student.phone |> Sms.verify_phone(student.verification_code)
        result

      result ->
        result
    end
  end

  @doc """
  Sets a new login code on the `student` and attempt time and sends a text with the new code.

  ## Returns
  `{:ok, student}` or `{:error, changeset}`
  """
  def create_login_attempt(student) do
    code = generate_verify_code()

    dateTime =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    result =
      student
      |> Ecto.Changeset.change(%{verification_code: code, login_attempt: dateTime})
      |> Repo.update()

    case result do
      {:ok, student} ->
        student.phone |> Sms.login_phone(student.verification_code)
        result

      result ->
        result
    end
  end

  defp convert_rand(num) do
    case num < 1.0 do
      true -> convert_rand(num * 10)
      false -> Kernel.round(num * 10_000)
    end
  end

  @doc """
  Sets the primary school if one doesn't already exist
  """
  def conditional_primary_school_set(student, school_id) do
    if student.primary_school_id == nil do
      student
      |> Ecto.Changeset.change(%{primary_school_id: school_id})
      |> Repo.update()
    else
      {:ok, student}
    end
  end

  @student_point_signup_type 2

  def get_org_raise_effort_for_student(%Student{id: student_id, primary_school_id: school_id}) do
    from(st in Student)
    |> join(:left, [st], s in Signup, on: st.id == s.student_id)
    |> join(:left, [st, s], o in Organization,
      on: o.custom_signup_link_id == s.custom_signup_link_id
    )
    |> join(:left, [st, s, o], cr_d in subquery(raise_direct_subquery(school_id)),
      on: cr_d.custom_signup_link_id == o.custom_signup_link_id
    )
    |> join(:left, [st, s, o], cr_i in subquery(raise_indirect_subquery(school_id)),
      on: cr_i.custom_signup_link_id == o.custom_signup_link_id
    )
    |> join(:left, [st, s, o], or_d in subquery(raise_direct_subquery(nil)),
      on: or_d.custom_signup_link_id == o.custom_signup_link_id
    )
    |> join(:left, [st, s, o], or_i in subquery(raise_indirect_subquery(nil)),
      on: or_i.custom_signup_link_id == o.custom_signup_link_id
    )
    |> join(:left, [st, s, o], ps in subquery(personal_signups()), on: ps.student_id == st.id)
    |> where([st, s, o], st.id == ^student_id)
    |> select([st, s, o, cr_d, cr_i, or_d, or_i, ps], %{
      org_signups:
        fragment("COALESCE(?, 0)", or_d.count) + fragment("COALESCE(?, 0)", or_i.count),
      chapter_signups:
        fragment("COALESCE(?, 0)", cr_i.count) + fragment("COALESCE(?, 0)", cr_d.count),
      personal_signups: fragment("COALESCE(?, 0)", ps.count),
      org_id: o.id,
      org_name: o.name
    })
    |> Repo.one()
  end

  @doc """
    Retrieve list of students referred by another students
  """
  def get_referred_students_by_student_id(referring_student_id) do
    from(student in Student,
      join: user in Skoller.Users.User, on: user.student_id == student.id,
      join: customers_info in Skoller.Payments.Stripe, on: customers_info.user_id == user.id,
      where: student.enrolled_by_student_id == ^referring_student_id,
      select: %{
        user: user,
        student: student,
        customer_info: customers_info
      }
    )
    |> Skoller.Repo.all()
    |> then(fn list ->
      {:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{status: "active"})
      Enum.reduce(list, [], fn %{user: user, student: student, customer_info: %{customer_id: customer_id}}, acc ->
        result =
        subscriptions
        |> Enum.find(& &1.customer == customer_id)
        |> then(fn

          nil ->
            :inactive
          customer ->

          customer
          |> Map.get(:plan)
          |> Map.get(:active, :not_available)
        end)

        [%{user: %{
          trial_start: user.trial_start,
          trial_end: user.trial_end,
          trial_status: getTrialStatus(user.trial_start, user.trial_end)
        },
        student: %{
          name: "#{student.name_first} #{student.name_last}"
        }, premium_active: result} | acc]
      end)
    end)
  end

  def compile_referred_students_report() do
    from(student in Student,
      join: user in Skoller.Users.User, on: user.student_id == student.id,
      join: customer_info in Skoller.Payments.Stripe, on: customer_info.user_id == user.id,
      join: enrolled_students in Student, on: enrolled_students.enrolled_by == student.id,
      where: not is_nil(student.enrolled_by),
      select: %{
        user: user,
        student: student,
        customer_info: customer_info
      }
    )
    |> Skoller.Repo.all()
  end

  defp getTrialStatus(trial_start, trial_end) do
    if Timex.between?(Date.utc_today, trial_start, trial_end) do
      :active
    else
      :inactive
    end
  end

  defp raise_direct_subquery(primary_school_id) do
    from(s in Student)
    |> join(:inner, [s], cs in Signup, on: cs.student_id == s.id)
    |> filter_chapter(primary_school_id)
    |> where([s, cs], fragment("? > '2019-05-31'", cs.inserted_at))
    |> group_by([s, cs], cs.custom_signup_link_id)
    |> select([s, cs], %{
      custom_signup_link_id: cs.custom_signup_link_id,
      count: count(cs.custom_signup_link_id)
    })
  end

  defp raise_indirect_subquery(primary_school_id) do
    from(s in Student)
    |> join(:inner, [s], cs in Signup, on: cs.student_id == s.id)
    |> join(:inner, [s, cs], p in StudentPoint, on: p.student_id == s.id)
    |> where(
      [s, cs, p],
      p.student_point_type_id == @student_point_signup_type and
        fragment("? > '2019-05-31'", p.inserted_at)
    )
    |> filter_chapter(primary_school_id)
    |> group_by([s, cs, p], cs.custom_signup_link_id)
    |> select([s, cs], %{
      custom_signup_link_id: cs.custom_signup_link_id,
      count: count(cs.custom_signup_link_id)
    })
  end

  defp filter_chapter(query, nil), do: query

  defp filter_chapter(query, school_id),
    do: where(query, [s], s.primary_school_id == ^school_id)

  defp personal_signups() do
    from(s in StudentPoint)
    |> where(
      [s],
      s.student_point_type_id == @student_point_signup_type and
        fragment("? > '2019-05-31'", s.inserted_at)
    )
    |> group_by([s], s.student_id)
    |> select([s], %{
      student_id: s.student_id,
      count: count(s.student_id)
    })
  end
end
