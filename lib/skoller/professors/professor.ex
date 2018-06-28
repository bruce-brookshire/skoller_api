defmodule Skoller.Professors.Professor do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Professors.Professor
  alias Skoller.Schools.School

  schema "professors" do
    field :email, :string
    field :name_first, :string
    field :name_last, :string
    field :office_availability, :string
    field :office_location, :string
    field :phone, :string
    field :school_id, :id
    belongs_to :school, School, define_field: false

    timestamps()
  end

  @req_fields [:name_last, :school_id]
  @opt_fields [:name_first, :email, :phone, :office_location,
              :office_availability]
  @all_fields @req_fields ++ @opt_fields
  @upd_fields [:name_first, :name_last, :email, :phone, :office_location,
              :office_availability]

  @doc false
  def changeset_insert(%Professor{} = professor, attrs) do
    professor
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:phone, ~r/^([0-9]{3}-)?[0-9]{3}-[0-9]{4}$/)
    |> foreign_key_constraint(:school_id)
  end

  def changeset_update(%Professor{} = professor, attrs) do
    professor
    |> cast(attrs, @upd_fields)
    |> validate_required(@req_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:phone, ~r/^([0-9]{3}-)?[0-9]{3}-[0-9]{4}$/)
  end
end
