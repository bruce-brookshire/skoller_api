defmodule Skoller.Students do
  @moduledoc """
  The Students context.
  """
  
  alias Skoller.Repo
  alias Skoller.Students.Student
  alias Skoller.Students.FieldOfStudy, as: StudentField
  alias Skoller.StudentClasses.EnrollmentLinks

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
end
