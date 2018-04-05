defmodule Classnavapi.ClassPeriod do

  @moduledoc """
  
  Changeset and schema for class_periods

  Validates that the end date is after the start date

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.ClassPeriod
  alias Classnavapi.Schools.School

  schema "class_periods" do
    field :name, :string
    field :school_id, :id
    belongs_to :school, School, define_field: false
    has_many :classes, Classnavapi.Class

    timestamps()
  end

  @req_fields [:name, :school_id]
  @all_fields @req_fields
  @upd_req [:name]
  @upd_all @upd_req
  
  @doc false
  def changeset_insert(%ClassPeriod{} = class_period, attrs) do
    class_period
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:school_id)
  end

  def changeset_update(%ClassPeriod{} = class_period, attrs) do
    class_period
    |> cast(attrs, @upd_all)
    |> validate_required(@upd_req)
  end
end
