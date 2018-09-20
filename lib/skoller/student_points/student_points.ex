defmodule Skoller.StudentPoints do
  @moduledoc """
  The context module for student points
  """

  alias Skoller.StudentPoints.StudentPoint
  alias Skoller.Repo

  import Ecto.Query

  def get_points_by_student_id(student_id) do
    points = from(sp in StudentPoint)
    |> where([sp], sp.student_id == ^student_id)
    |> Repo.aggregate(:sum, :value)

    case is_nil(points) do
      true -> 0
      false -> points
    end
  end
end