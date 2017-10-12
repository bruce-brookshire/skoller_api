defmodule Classnavapi.ClassPeriod do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.ClassPeriod


  schema "class_periods" do
    field :end_date, :date
    field :name, :string
    field :start_date, :date
    field :school_id, :id
    belongs_to :school, Classnavapi.School, define_field: false

    timestamps()
  end

  def validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)
    case start_date < end_date do
      true -> changeset
      false -> add_error(changeset, :start_date, "Start date occurs after end date.")
    end
  end

  @doc false
  def changeset(%ClassPeriod{} = class_period, attrs) do
    class_period
    |> cast(attrs, [:name, :start_date, :end_date, :school_id])
    |> validate_required([:name, :start_date, :end_date, :school_id])
    |> foreign_key_constraint(:school_id)
    |> validate_dates
  end
end
