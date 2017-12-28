defmodule Classnavapi.ClassPeriod do

  @moduledoc """
  
  Changeset and schema for class_periods

  Validates that the end date is after the start date

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Helpers.ChangesetValidation

  schema "class_periods" do
    field :end_date, :utc_datetime
    field :name, :string
    field :start_date, :utc_datetime
    field :school_id, :id
    belongs_to :school, Classnavapi.School, define_field: false
    has_many :classes, Classnavapi.Class

    timestamps()
  end

  @req_fields [:name, :start_date, :end_date, :school_id]
  @all_fields @req_fields
  @upd_fields [:name, :start_date, :end_date]

  @doc false
  def changeset_insert(%ClassPeriod{} = class_period, attrs) do
    class_period
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:school_id)
    |> ChangesetValidation.validate_dates(:start_date, :end_date)
  end

  def changeset_update(%ClassPeriod{} = class_period, attrs) do
    class_period
    |> cast(attrs, @upd_fields)
    |> validate_required(@req_fields)
    |> ChangesetValidation.validate_dates(:start_date, :end_date)
  end
end
