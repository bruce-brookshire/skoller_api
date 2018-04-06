defmodule Skoller.Schools.Class do
  
  @moduledoc """
  
  Changeset and schema for classes.

  Weights are validated for summing to 100.

  Weights can only be added through editing the class initially. Weights are edited individually after.

  Required fields: name, number, meet_days, meet_start_time, meet_end_time,
                seat_count, grade_scale,
                is_editable, class_period_id, is_syllabus

  Optional fields: crn, credits, location, professor_id, class_type, is_points

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Class.Doc
  alias Skoller.Professor
  alias Skoller.Class.Weight
  alias Skoller.Class.Status
  alias Skoller.Student
  alias Skoller.Class.HelpRequest
  alias Skoller.Class.ChangeRequest
  alias Skoller.Class.StudentRequest
  alias Skoller.Class.Assignment

  schema "classes" do
    field :credits, :string
    field :crn, :string
    field :is_chat_enabled, :boolean, default: true
    field :is_assignment_posts_enabled, :boolean, default: true
    field :is_editable, :boolean, default: true
    field :is_ghost, :boolean, default: true
    field :is_syllabus, :boolean, default: true
    field :is_points, :boolean, default: false
    field :location, :string
    field :meet_days, :string, default: ""
    field :meet_end_time, :string
    field :meet_start_time, :string
    field :name, :string
    field :code, :string
    field :subject, :string
    field :section, :string
    field :seat_count, :integer
    field :professor_id, :id
    field :class_period_id, :id
    field :class_status_id, :id
    field :grade_scale, :map
    field :class_type, :string
    field :campus, :string, default: ""
    field :class_upload_key, :string
    field :is_student_created, :boolean, default: false
    field :is_new_class, :boolean, default: false
    has_many :docs, Doc
    belongs_to :professor, Professor, define_field: false
    belongs_to :class_period, ClassPeriod, define_field: false
    has_many :weights, Weight
    belongs_to :class_status, Status, define_field: false
    has_one :school, through: [:class_period, :school]
    many_to_many :students, Student, join_through: "student_classes"
    has_many :help_requests, HelpRequest
    has_many :change_requests, ChangeRequest
    has_many :student_requests, StudentRequest
    has_many :assignments, Assignment

    timestamps()
  end

  @req_fields [:name, :is_editable, :class_period_id, :is_chat_enabled, :is_assignment_posts_enabled,
    :is_syllabus, :grade_scale, :is_points, :meet_start_time, :meet_days]
  @opt_fields [:professor_id, :location, :meet_end_time]

  @req_uni_fields @req_fields ++ [:code, :section, :subject]
  @opt_uni_fields @opt_fields ++ [:crn, :credits, :class_type, :campus, :seat_count]
  @all_uni_fields @req_uni_fields ++ @opt_uni_fields

  @req_hs_fields @req_fields
  @opt_hs_fields @opt_fields
  @all_hs_fields @req_hs_fields ++ @opt_hs_fields

  @doc false
  def hs_changeset(%Class{} = class, attrs) do
    class
    |> cast(attrs, @all_hs_fields)
    |> validate_required(@req_hs_fields)
    |> update_change(:name, &title_case(&1))
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> unique_constraint(:class, name: :unique_class_index)
  end
  
  @doc false
  def university_changeset(%Class{} = class, attrs) do
    class
    |> cast(attrs, @all_uni_fields)
    |> validate_required(@req_uni_fields)
    |> update_change(:name, &title_case(&1))
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
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
end
  