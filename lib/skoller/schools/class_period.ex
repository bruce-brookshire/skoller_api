defmodule Skoller.Schools.ClassPeriod do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Schools.School
  alias Skoller.Schools.Class

  schema "class_periods" do
    field :name, :string
    field :school_id, :id
    belongs_to :school, School, define_field: false
    has_many :classes, Class

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
