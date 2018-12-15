defmodule Skoller.Periods.ClassPeriod do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Schools.School
  alias Skoller.Classes.Class
  alias Skoller.Periods.Status

  schema "class_periods" do
    field :name, :string
    field :school_id, :id
    field :is_hidden, :boolean, default: false
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    field :is_main_period, :boolean, default: false
    field :class_period_status_id, :id
    belongs_to :school, School, define_field: false
    has_many :classes, Class
    belongs_to :class_period_status, Status, define_field: false

    timestamps()
  end

  @req_fields [:name, :school_id, :start_date, :end_date]
  @all_fields @req_fields
  @upd_req [:name, :start_date, :end_date]
  @upd_all @upd_req
  
  @doc false
  def changeset_insert(%ClassPeriod{} = class_period, attrs) do
    class_period
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:school_id)
    |> unique_constraint(:class_periods, name: :unique_semester_index)
  end

  def changeset_update(%ClassPeriod{} = class_period, attrs) do
    class_period
    |> cast(attrs, @upd_all)
    |> validate_required(@upd_req)
  end
end
