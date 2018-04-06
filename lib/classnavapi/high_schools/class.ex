defmodule Classnavapi.HighSchools.Class do
  
    @moduledoc """
    
    Changeset and schema for classes.
  
    Weights are validated for summing to 100.
  
    Weights can only be added through editing the class initially. Weights are edited individually after.
  
    Required fields: name, number, meet_days, meet_start_time, meet_end_time,
                  seat_count, is_enrollable, grade_scale,
                  is_editable, class_period_id, is_syllabus
  
    Optional fields: crn, credits, location, professor_id, class_type, is_points
  
    """
  
    use Ecto.Schema
    import Ecto.Changeset
    alias Classnavapi.HighSchools.Class
    alias Classnavapi.Schools.ClassPeriod
    alias Classnavapi.Class.Doc
    alias Classnavapi.Professor
    alias Classnavapi.Class.Weight
    alias Classnavapi.Class.Status
    alias Classnavapi.Student
    alias Classnavapi.Class.HelpRequest
    alias Classnavapi.Class.ChangeRequest
    alias Classnavapi.Class.StudentRequest
    alias Classnavapi.Class.Assignment
  
    schema "classes" do
      field :credits, :string
      field :crn, :string
      field :is_chat_enabled, :boolean, default: true
      field :is_assignment_posts_enabled, :boolean, default: true
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
  
    @req_fields [:name, :number, :is_editable, :class_period_id, :is_syllabus, 
                  :is_chat_enabled, :is_assignment_posts_enabled,
                  :is_enrollable, :grade_scale]
    @opt_fields [:crn, :credits, :location, :professor_id, :class_type, :is_points,
                  :meet_start_time, :meet_end_time, :campus, :meet_days, :seat_count]
    @all_fields @req_fields ++ @opt_fields
  
    @doc false
    def changeset(%Class{} = class, attrs) do
      class
      |> cast(attrs, @all_fields)
      |> validate_required(@req_fields)
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
  