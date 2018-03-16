defmodule Classnavapi.Class do

  @moduledoc """
  
  Changeset and schema for classes.

  Weights are validated for summing to 100.

  Weights can only be added through editing the class initially. Weights are edited individually after.

  Required fields: name, number, meet_days, meet_start_time, meet_end_time,
                seat_count, class_start, class_end, is_enrollable, grade_scale,
                is_editable, class_period_id, is_syllabus

  Optional fields: crn, credits, location, professor_id, class_type, is_points

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Class
  alias Classnavapi.Helpers.ChangesetValidation

  schema "classes" do
    field :class_end, :utc_datetime
    field :class_start, :utc_datetime
    field :credits, :string
    field :crn, :string
    field :is_chat_enabled, :boolean, default: true
    field :is_editable, :boolean, default: true
    field :is_enrollable, :boolean, default: true
    field :is_ghost, :boolean, default: true
    field :is_syllabus, :boolean, default: true
    field :is_points, :boolean
    field :location, :string
    field :meet_days, :string, default: ""
    field :meet_end_time, :string
    field :meet_start_time, :string
    field :name, :string
    field :number, :string
    field :seat_count, :integer
    field :professor_id, :id
    field :class_period_id, :id
    field :class_status_id, :id
    field :grade_scale, :string
    field :grade_scale_map, :map
    field :class_type, :string
    field :campus, :string, default: ""
    field :class_upload_key, :string
    field :is_student_created, :boolean, default: false
    field :is_new_class, :boolean, default: false
    has_many :docs, Classnavapi.Class.Doc
    belongs_to :professor, Classnavapi.Professor, define_field: false
    belongs_to :class_period, Classnavapi.ClassPeriod, define_field: false
    has_many :weights, Class.Weight
    belongs_to :class_status, Classnavapi.Class.Status, define_field: false
    has_one :school, through: [:class_period, :school]
    many_to_many :students, Classnavapi.Student, join_through: "student_classes"
    has_many :help_requests, Classnavapi.Class.HelpRequest
    has_many :change_requests, Classnavapi.Class.ChangeRequest
    has_many :student_requests, Classnavapi.Class.StudentRequest
    has_many :assignments, Classnavapi.Class.Assignment

    timestamps()
  end

  @req_fields [:name, :number, :class_start, :class_end, 
                :is_enrollable,
                :is_editable, :class_period_id, :is_syllabus, :is_chat_enabled, :grade_scale_map]
  @opt_fields [:crn, :credits, :location, :professor_id, :class_type, :is_points,
                :meet_start_time, :meet_end_time, :campus, :meet_days, :seat_count, :grade_scale]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Class{} = class, attrs) do
    class
    |> cast(attrs, @all_fields)
    |> put_grade_scale()
    |> validate_required(@req_fields)
    |> update_change(:name, &title_case(&1))
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> ChangesetValidation.validate_dates(:class_start, :class_end)
    |> unique_constraint(:class, name: :unique_class_index)
  end

  defp title_case(str) do
    str
    |> String.split()
    |> Enum.map(&capitalize(&1))
    |> Enum.reduce("", & &2 <> " " <> &1)
    |> String.trim()
  end

  defp capitalize(string) do
    cond do
      string in ["II", "III", "IV", "VI", "VIII", "IX"] -> string
      string in ["ii", "iii", "iv", "vi", "viii", "ix"] -> string |> String.upcase
      true -> String.capitalize(string)
    end
  end

  defp put_grade_scale(%Ecto.Changeset{valid?: true, changes:
    %{grade_scale_map: grade_scale_map}} = changeset), do: changeset
  end
  defp put_grade_scale(%Ecto.Changeset{valid?: true, changes:
    %{grade_scale: grade_scale}} = changeset) do
    change(changeset, %{grade_scale_map: convert_grade_scale(grade_scale)})
  end
  defp put_grade_scale(changeset), do: changeset

  defp convert_grade_scale(gs) do
    gs
    |> String.trim_trailing("|")
    |> String.split("|")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.sort(&List.last(&1) >= List.last(&2))
    |> Enum.reduce(%{}, &Map.put(&2, List.first(&1), List.last(&1)))
  end
end
