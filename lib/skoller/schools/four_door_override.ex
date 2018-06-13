defmodule Skoller.Schools.FourDoorOverride do
  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Schools.FourDoorOverride


  schema "four_door_overrides" do
    field :is_auto_syllabus, :boolean, default: false
    field :is_diy_enabled, :boolean, default: false
    field :is_diy_preferred, :boolean, default: false
    field :school_id, :id

    timestamps()
  end

  @req_fields [:is_diy_preferred, :is_diy_enabled, :is_auto_syllabus, :school_id]
  @all_fields @req_fields

  @doc false
  def changeset(%FourDoorOverride{} = four_door_override, attrs) do
    four_door_override
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:school_id)
    |> unique_constraint(:school_id)
  end
end
