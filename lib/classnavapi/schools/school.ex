defmodule Classnavapi.Schools.School do

  @moduledoc """
  
  Defines schema and changeset for school

  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Classnavapi.Schools.School
  alias Classnavapi.Schools.ClassPeriod

  schema "schools" do
    field :adr_city, :string
    field :adr_line_1, :string
    field :adr_line_2, :string
    field :adr_state, :string
    field :adr_zip, :string
    field :is_readonly, :boolean
    field :is_diy_enabled, :boolean
    field :is_diy_preferred, :boolean
    field :is_auto_syllabus, :boolean
    field :name, :string
    field :timezone, :string
    field :short_name, :string
    field :is_chat_enabled, :boolean, default: true
    field :is_assignment_posts_enabled, :boolean, default: true
    has_many :class_periods, ClassPeriod
    has_many :classes, through: [:class_periods, :classes]

    timestamps()
  end

  @req_fields [:name, :adr_line_1, :adr_city, :adr_state, :adr_zip, :timezone, :is_chat_enabled, :is_assignment_posts_enabled]
  @opt_fields [:adr_line_2, :is_readonly,
              :is_diy_enabled, :is_diy_preferred, :is_auto_syllabus, :short_name]
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
  defp readonly(changeset, true) do
    changeset
    |> fresh_readonly(get_change(changeset, :is_readonly))
  end

  defp fresh_readonly(changeset, true), do: changeset
  defp fresh_readonly(changeset, _) do
    changeset
    |> add_error(:is_readonly, "School is read only.")
  end

  defp validate_editable(changeset) do
    changeset
    |> readonly(get_field(changeset, :is_readonly))
  end
end
