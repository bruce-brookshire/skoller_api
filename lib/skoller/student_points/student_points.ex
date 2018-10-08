defmodule Skoller.StudentPoints do
  @moduledoc """
  The context module for student points
  """

  alias Skoller.StudentPoints.StudentPoint
  alias Skoller.StudentPoints.PointType
  alias Skoller.Repo
  alias Skoller.StudentPoints.Emails

  import Ecto.Query

  @doc """
  Gets the total amount of points for a student.

  Returns an `integer`
  """
  def get_points_by_student_id(student_id) do
    points = from(sp in StudentPoint)
    |> where([sp], sp.student_id == ^student_id)
    |> Repo.aggregate(:sum, :value)

    case is_nil(points) do
      true -> 0
      false -> points
    end
  end

  @doc """
  Adds points to a student based on the points set for `point_name` in `PointType`

  Returns `{:ok, StudentPoint}` or `{:error, changeset}`
  """
  def add_points_to_student(student_id, point_name) do
    point_type = Repo.get_by!(PointType, name: point_name)

    case Repo.insert(%StudentPoint{student_id: student_id, student_point_type_id: point_type.id, value: point_type.value}) do
      {:ok, points} ->
        check_1000_point_threshold(student_id) 
        {:ok, points}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def check_1000_point_threshold(student_id) do
    points = get_points_by_student_id(student_id)
    if points >= 1000 do
      Emails.send_one_thousand_points_email(student_id)
    end
  end
end