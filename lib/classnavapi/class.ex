defmodule Classnavapi.Class do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class


  schema "classes" do
    field :class_end, :date
    field :class_start, :date
    field :credits, :string
    field :crn, :string
    field :is_editable, :boolean, default: false
    field :is_enrollable, :boolean, default: false
    field :is_syllabus, :boolean, default: true
    field :location, :string
    field :meet_days, :string
    field :meet_end_time, :string
    field :meet_start_time, :string
    field :name, :string
    field :number, :string
    field :seat_count, :integer
    field :professor_id, :id
    field :class_period_id, :id
    field :class_status_id, :id
    belongs_to :professor, Classnavapi.Professor, define_field: false
    belongs_to :class_period, Classnavapi.ClassPeriod, define_field: false

    timestamps()
  end

  @req_fields [:name, :number,  :meet_days, :meet_start_time, :meet_end_time, :seat_count, :class_start, :class_end, :is_enrollable, :is_editable, :class_period_id, :is_syllabus, :class_status_id]
  @opt_fields [:crn, :credits, :location, :professor_id]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Class{} = class, attrs) do
    class
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> foreign_key_constraint(:class_status_id)
  end
end
