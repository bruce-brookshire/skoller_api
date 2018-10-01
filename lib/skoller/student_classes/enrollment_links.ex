defmodule Skoller.StudentClasses.EnrollmentLinks do
  @moduledoc """
  A context module for student class enrollment links
  """
  
  alias Skoller.Repo
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.StudentClasses

  @link_length 5

  @doc """
  Gets a student class from an enrollment link.

  ## Returns
  `Skoller.StudentClasses.StudentClass` with `:student` and `:class` loaded, or `Ecto.NoResultsError`
  """
  def get_student_class_by_enrollment_link(link) do
    student_class_id = link |> String.split_at(@link_length) |> elem(1)
    Repo.get_by!(StudentClass, enrollment_link: link, id: student_class_id)
    |> Repo.preload([:student, :class])
  end

  @doc """
  Generates a link with `@link_length` random characters, with the id appended.

  ## Returns
  `Binary`
  """
  def generate_link(id) do
    @link_length
    |> :crypto.strong_rand_bytes() 
    |> Base.url_encode64 
    |> binary_part(0, @link_length)
    |> Kernel.<>(to_string(id))
  end

  @doc """
  Enroll in a class with a student link.

  Similar to `Skoller.StudentClasses.enroll_in_class/3`
  """
  def enroll_by_link(link, student_id, params) do
    sc = get_student_class_by_enrollment_link(link)
    params = params |> Map.put("class_id", sc.class_id) |> Map.put("student_id", student_id)
    StudentClasses.enroll(student_id, sc.class_id, params, [enrolled_by: sc.id])
  end
end