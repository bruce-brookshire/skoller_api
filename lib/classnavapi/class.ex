defmodule Classnavapi.Class do

  @moduledoc """
  
  Changeset and schema for classes.

  Weights are validated for summing to 100.

  Weights can only be added through editing the class initially. Weights are edited individually after.

  Required fields: name, number, meet_days, meet_start_time, meet_end_time,
                seat_count, class_start, class_end, is_enrollable, grade_scale,
                is_editable, class_period_id, is_syllabus

  Optional fields: crn, credits, location, professor_id, class_type, is_points

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class
  alias Classnavapi.Helpers.ChangesetValidation
  alias Classnavapi.Repo
  alias Ecto.Changeset

  @needs_syllabus_status 200

  schema "classes" do
    field :class_end, :utc_datetime
    field :class_start, :utc_datetime
    field :credits, :string
    field :crn, :string
    field :is_editable, :boolean, default: true
    field :is_enrollable, :boolean, default: true
    field :is_ghost, :boolean, default: true
    field :is_syllabus, :boolean, default: true
    field :is_points, :boolean
    field :location, :string
    field :meet_days, :string, default: ""
    field :meet_end_time, :string, default: ""
    field :meet_start_time, :string, default: ""
    field :name, :string
    field :number, :string
    field :seat_count, :integer
    field :professor_id, :id
    field :class_period_id, :id
    field :class_status_id, :id, default: @needs_syllabus_status
    field :grade_scale, :string
    field :class_type, :string
    field :campus, :string, default: ""
    field :class_upload_key, :string
    has_many :docs, Classnavapi.Class.Doc
    belongs_to :professor, Classnavapi.Professor, define_field: false
    belongs_to :class_period, Classnavapi.ClassPeriod, define_field: false
    has_many :weights, Class.Weight
    belongs_to :class_status, Classnavapi.Class.Status, define_field: false
    has_one :school, through: [:class_period, :school]
    many_to_many :students, Classnavapi.Student, join_through: "student_classes"
    has_many :help_requests, Classnavapi.Class.HelpRequest
    has_many :change_requests, Classnavapi.Class.ChangeRequest
    has_many :assignments, Classnavapi.Class.Assignment

    timestamps()
  end

  @req_fields [:name, :number, :class_start, :class_end, 
                :is_enrollable, :grade_scale,
                :is_editable, :class_period_id, :is_syllabus]
  @opt_fields [:crn, :credits, :location, :professor_id, :class_type, :is_points,
                :meet_start_time, :meet_end_time, :campus, :meet_days, :seat_count]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset_insert(%Class{} = class, attrs) do
    class
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> ChangesetValidation.validate_dates(:class_start, :class_end)
    |> unique_constraint(:class, name: :unique_class_index)
  end

  def changeset_update(%Class{} = class, attrs) do
    class
    |> Repo.preload(:weights)
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> ChangesetValidation.validate_dates(:class_start, :class_end)
    |> cast_assoc(:weights)
    |> validate_weight_totals()
    |> unique_constraint(:class, name: :unique_class_index)
  end

  defp sum_weight(list) do
    case list do
      [] -> list
      _ -> list |> Enum.reduce(Decimal.new(0), &(Decimal.add(&1, &2)))
    end
  end

  defp validate_weight_totals(%Ecto.Changeset{changes: %{weights: _weights}} = changeset) do
    case changeset |> get_field(:is_points) do
      false -> changeset |> validate_weight_pct()
      true -> changeset
    end
  end
  defp validate_weight_totals(changeset), do: changeset

  defp validate_weight_pct(changeset) do
    sum = changeset
          |> Changeset.get_field(:weights)
          |> Enum.map(&Map.get(&1, :weight))
          |> Enum.filter(& &1)
          |> sum_weight

    target = Decimal.new(100)

    equal = Decimal.cmp(sum, target)

    cond do
    sum == [] -> changeset
    equal == :eq -> changeset
    true -> changeset |> add_error(:weights, "Weights do not add to 100")
    end
  end
end
