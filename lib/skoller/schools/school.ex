defmodule Skoller.Schools.School do

  @moduledoc """
  
  Defines schema and changeset for school

  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Skoller.Schools.School
  alias Skoller.Schools.ClassPeriod

  schema "schools" do
    field :adr_country, :string
    field :adr_locality, :string
    field :adr_line_1, :string
    field :adr_line_2, :string
    field :adr_line_3, :string
    field :adr_region, :string
    field :adr_zip, :string
    field :is_readonly, :boolean, default: false
    field :name, :string
    field :timezone, :string
    field :short_name, :string
    field :is_chat_enabled, :boolean, default: true
    field :is_assignment_posts_enabled, :boolean, default: true
    field :is_university, :boolean, default: true
    has_many :class_periods, ClassPeriod
    has_many :classes, through: [:class_periods, :classes]

    timestamps()
  end

  @req_fields [:name, :adr_locality, :adr_region, :is_chat_enabled, :is_assignment_posts_enabled, :is_university, :adr_country]
  @opt_fields [:adr_line_1, :adr_line_2, :adr_zip, :is_readonly, :adr_line_3, :short_name, :timezone]
  @all_fields @req_fields ++ @opt_fields
  @upd_fields @all_fields

  @doc false
  def changeset_insert(%School{} = school, attrs) do
    school
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  def changeset_update(%School{} = school, attrs) do
    school
    |> cast(attrs, @upd_fields)
    |> validate_required(@req_fields)
    |> validate_editable()
  end

  defp readonly(changeset, false), do: changeset
  defp readonly(%{changes: %{is_readonly: true}} = changeset, true), do: changeset
  defp readonly(changeset, true) do
    changeset
    |> add_error(:is_readonly, "School is read only.")
  end

  defp validate_editable(changeset) do
    changeset
    |> readonly(get_field(changeset, :is_readonly))
  end
end
