defmodule Skoller.StudentPoints.StudentPoint do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.StudentPoints.StudentPoint

  schema "student_points" do
    field :value, :integer
    field :student_id, :id
    field :student_point_type_id, :id

    timestamps()
  end

  @req_fields [:value, :student_id, :student_point_type_id]
  @all_fields @req_fields

  @doc false
  def changeset(%StudentPoint{} = point, attrs) do
    point
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
