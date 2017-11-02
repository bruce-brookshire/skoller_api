defmodule Classnavapi.Class do

  @moduledoc """
  
  Changeset and schema for classes.

  Weights are validated for summing to 100.

  Weights can only be added through editing the class initially. Weights are edited individually after.

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class
  alias Classnavapi.Helpers.ChangesetValidation
  alias Classnavapi.Repo
  alias Ecto.Changeset

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
    has_many :docs, Classnavapi.Class.Doc
    belongs_to :professor, Classnavapi.Professor, define_field: false
    belongs_to :class_period, Classnavapi.ClassPeriod, define_field: false
    has_many :weights, Class.Weight
    belongs_to :class_status, Classnavapi.Class.Status, define_field: false
    has_one :school, through: [:class_period, :school]

    timestamps()
  end

  defp sum_weight(list) do
    case list do
      [] -> list
      _ -> list |> Enum.reduce(Decimal.new(0), &(Decimal.add(&1, &2)))
    end
  end

  defp validate_weight_totals(changeset) do
    sum = changeset
          |> Changeset.get_field(:weights)
          |> Enum.map(&Map.get(&1, :weight))
          |> Enum.filter(& &1)
          |> sum_weight

    target = Decimal.new(100)

    cond do
      sum == [] -> changeset
      sum == target -> changeset
      sum != target -> changeset |> add_error(:weights, "Weights do not add to 100")
    end
  end

  @req_fields [:name, :number,  :meet_days, :meet_start_time, :meet_end_time,
                :seat_count, :class_start, :class_end, :is_enrollable,
                :is_editable, :class_period_id, :is_syllabus, :class_status_id]
  @opt_fields [:crn, :credits, :location, :professor_id]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset_insert(%Class{} = class, attrs) do
    class
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> foreign_key_constraint(:class_status_id)
    |> ChangesetValidation.validate_dates(:class_start, :class_end)
  end

  def changeset_update(%Class{} = class, attrs) do
    class = Repo.preload class, :weights

    class
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> foreign_key_constraint(:class_status_id)
    |> ChangesetValidation.validate_dates(:class_start, :class_end)
    |> cast_assoc(:weights)
    |> validate_weight_totals()
  end
end
