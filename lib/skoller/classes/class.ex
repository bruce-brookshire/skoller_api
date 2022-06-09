defmodule Skoller.Classes.Class do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.ClassDocs.Doc
  alias Skoller.Professors.Professor
  alias Skoller.Weights.Weight
  alias Skoller.ClassStatuses.Status
  alias Skoller.Students.Student
  alias Skoller.HelpRequests.HelpRequest
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.StudentRequests.StudentRequest
  alias Skoller.Assignments.Assignment
  alias Skoller.Classes.Note
  alias Skoller.Users.User
  alias Skoller.Organizations.StudentOrgInvitations.StudentOrgInvitation

  schema "classes" do
    field :premium, :integer, default: 0
    field :trial, :integer, default: 0
    field :expired, :integer, default: 0
    field :received, :string
    field :days_left, :integer
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
    field :meet_end_time, :time
    field :meet_start_time, :time
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
    field :created_by, :id
    field :updated_by, :id
    field :created_on, :string
    has_many :docs, Doc
    belongs_to :professor, Professor, define_field: false
    belongs_to :student_org_inventations, StudentOrgInventations
    belongs_to :class_period, ClassPeriod, define_field: false
    belongs_to :created_by_user, User, define_field: false, foreign_key: :created_by
    belongs_to :updated_by_user, User, define_field: false, foreign_key: :updated_by
    has_many :weights, Weight
    belongs_to :class_status, Status, define_field: false
    has_one :school, through: [:class_period, :school]
    many_to_many :students, Student, join_through: "student_classes"
    has_many :help_requests, HelpRequest
    has_many :change_requests, ChangeRequest
    has_many :student_requests, StudentRequest
    has_many :assignments, Assignment
    has_many :notes, Note

    timestamps()
  end

  @req_fields [:name, :is_editable, :class_period_id, :is_chat_enabled, :is_assignment_posts_enabled,
    :is_syllabus, :is_points, :section]
  @opt_fields [:premium, :trial, :expired, :received, :days_left, :professor_id, :location, :meet_end_time, :meet_start_time, :class_upload_key, :grade_scale]

  @req_uni_fields @req_fields ++ [:code, :subject, :meet_days]
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
    |> mandatory_validations
  end

  @doc false
  #TODO: Remove this temp jank code once flutter is deployed
  def university_changeset(%Class{} = class, attrs) do

    #This makes sure that meet_start_time being "online" doesnt fail the creation
    {_, attrs} = Map.get_and_update(attrs, "meet_start_time",
      fn current_value ->
        if current_value == nil do
          :pop
        else
          case Time.from_iso8601(current_value) do
            {:error, _} -> :pop
            _ -> {current_value, current_value}
          end
        end
      end)

    class
    |> cast(attrs, @all_uni_fields)
    |> validate_required(@req_uni_fields)
    |> mandatory_validations
  end

  defp mandatory_validations(changeset) do
    changeset
    # |> update_change(:name, &title_case(&1))
    |> foreign_key_constraint(:class_period_id)
    |> foreign_key_constraint(:professor_id)
    |> unique_constraint(:class, name: :unique_class_index)
  end
end
