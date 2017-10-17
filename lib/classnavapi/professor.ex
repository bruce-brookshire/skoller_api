defmodule Classnavapi.Professor do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Professor


  schema "professors" do
    field :email, :string
    field :name_first, :string
    field :name_last, :string
    field :office_availability, :string
    field :office_location, :string
    field :phone, :string
    field :class_period_id, :id
    belongs_to :class_period, Classnavapi.ClassPeriod, define_field: false

    timestamps()
  end

  @all_fields [:name_first, :name_last, :email, :phone, :office_location, :office_availability, :class_period_id]
  @req_fields [:name_last, :class_period_id]

  @doc false
  def changeset(%Professor{} = professor, attrs) do
    professor
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:class_period_id)
  end
end
