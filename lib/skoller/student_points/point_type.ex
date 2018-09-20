defmodule Skoller.StudentPoints.PointType do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.StudentPoints.PointType

  schema "student_point_types" do
    field :is_one_time, :boolean, default: false
    field :name, :string
    field :value, :integer

    timestamps()
  end

  @req_fields [:name, :value, :is_one_time]
  @all_fields @req_fields

  @doc false
  def changeset(%PointType{} = point_type, attrs) do
    point_type
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end
end
