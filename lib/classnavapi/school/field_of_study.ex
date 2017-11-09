defmodule Classnavapi.School.FieldOfStudy do
  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.School.FieldOfStudy


  schema "fields_of_study" do
    field :field, :string
    field :school_id, :id

    timestamps()
  end

  @doc false
  def changeset(%FieldOfStudy{} = field_of_study, attrs) do
    field_of_study
    |> cast(attrs, [:field])
    |> validate_required([:field])
  end
end
