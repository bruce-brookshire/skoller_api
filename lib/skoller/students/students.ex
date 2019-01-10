defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Students.FieldOfStudy, as: StudentField
  alias Skoller.StudentClasses.EnrollmentLinks
  alias Skoller.Students.Sms

  import Ecto.Query

  require Logger


  @doc """
  Gets a student by id.

  ## Returns
  `Skoller.Students.Student` or `Ecto.NoResultsError`
  """
  def get_student_by_id!(student_id) do
    Repo.get!(Student, student_id)
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
    result = student
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
  Checks the verification code of the `student` against the `code`.

  Returns a boolean
  """
  def check_verification_code(student, code) do
    case student.verification_code == code do
      true -> 
        student |> verify_student()
        true
      false ->
        false
    end
  end

  defp convert_rand(num) do
    case num < 1.0 do
      true -> convert_rand(num * 10)
      false -> Kernel.round(num * 10_000)
    end
  end

  defp verify_student(student) do
    student 
    |> Ecto.Changeset.change(%{is_verified: true})
    |> Repo.update!
  end

  @doc """
  Sets the primary school if one doesn't already exist
  """
  def conditional_primary_school_set(student, school_id) do
    if (student.primary_school_id == nil) do
      student
      |> Ecto.Changeset.change(%{primary_school_id: school_id})
      |> Repo.update
    else
      {:ok, student}
    end
  end
end
