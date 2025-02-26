defmodule Skoller.Students.Student do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Students.Student
  alias Skoller.Users.User
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.Classes.Class
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Schools.School
  alias Skoller.Organizations.Organization
  alias Skoller.SkollerJobs.DegreeType
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Repo
  import Ecto.Query

  schema "students" do
    field :birthday, :date
    field :gender, :string
    field :name_first, :string
    field :name_last, :string
    field :phone, :string
    field :verification_code, :string
    field :login_attempt, :utc_datetime
    field :notification_time, :time
    field :future_reminder_notification_time, :time

    field :notification_days_notice, :integer,
      default: System.get_env("DEFAULT_NOTIFICATION_DAYS") |> String.to_integer()

    field :is_notifications, :boolean, default: true
    field :is_mod_notifications, :boolean, default: true
    field :is_reminder_notifications, :boolean, default: true
    field :is_chat_notifications, :boolean, default: true
    field :is_assign_post_notifications, :boolean, default: true
    field :organization, :string
    field :bio, :string
    field :grad_year, :string
    field :enrollment_link, :string
    field :primary_school_id, :id
    field :primary_period_id, :id
    field :primary_organization_id, :id
    field :todo_days_past, :integer
    field :todo_days_future, :integer
    field :degree_type_id, :id
    field :venmo_handle, :string

    many_to_many :fields_of_study, FieldOfStudy, join_through: "student_fields_of_study"
    many_to_many :classes, Class, join_through: "student_classes"

    has_many :student_classes, StudentClass
    has_many :student_assignments, through: [:student_classes, :student_assignments]
    has_many :schools, through: [:classes, :school]
    has_many :enrolled_students, Student, foreign_key: :enrolled_by_student_id

    has_one :user, User

    belongs_to :enrolled_by_student, Student
    belongs_to :primary_school, School, define_field: false
    belongs_to :primary_period, ClassPeriod, define_field: false
    belongs_to :degree_type, DegreeType, define_field: false
    belongs_to :primary_organization, Organization, define_field: false

    timestamps()
  end

  @req_fields [
    :name_first,
    :name_last,
    :phone,
    :notification_time,
    :notification_days_notice,
    :is_notifications,
    :is_mod_notifications,
    :is_reminder_notifications,
    :is_chat_notifications,
    :is_assign_post_notifications,
    :future_reminder_notification_time
  ]
  @opt_fields [
    :birthday,
    :gender,
    :organization,
    :bio,
    :grad_year,
    :primary_school_id,
    :primary_period_id,
    :primary_organization_id,
    :todo_days_past,
    :todo_days_future,
    :degree_type_id,
    :venmo_handle
  ]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Student{} = student, attrs) do
    student
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_length(:grad_year, is: 4)
    |> check_phone()
  end

  defp check_phone(%Ecto.Changeset{valid?: true, changes: %{phone: phone}} = changeset) do
    q = from s in Student, where: s.phone == ^phone

    case Repo.all(q) do
      [] -> changeset
      _phone -> changeset |> add_error(:phone, "Phone exists.")
    end
  end

  defp check_phone(changeset), do: changeset

  def with_primary_school(student) do
    student |> Repo.preload(:primary_school)
  end
end
