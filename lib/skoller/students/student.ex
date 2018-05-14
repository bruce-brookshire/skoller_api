defmodule Skoller.Students.Student do

  @moduledoc """

  Defines the schema and changeset for students

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Skoller.Students.Student
  alias Skoller.Users.User
  alias Skoller.FieldsOfStudy.FieldOfStudy
  alias Skoller.Schools.Class
  alias Skoller.Class.StudentClass

  schema "students" do
    field :birthday, :date
    field :gender, :string
    field :name_first, :string
    field :name_last, :string
    field :phone, :string
    field :verification_code, :string
    field :is_verified, :boolean
    field :notification_time, :time
    field :future_reminder_notification_time, :time
    field :notification_days_notice, :integer, default: 1
    field :is_notifications, :boolean, default: true
    field :is_mod_notifications, :boolean, default: true
    field :is_reminder_notifications, :boolean, default: true
    field :is_chat_notifications, :boolean, default: true
    field :is_assign_post_notifications, :boolean, default: true
    field :is_university, :boolean, default: true
    field :organization, :string
    field :bio, :string
    field :grad_year, :string
    has_many :users, User
    many_to_many :fields_of_study, FieldOfStudy, join_through: "student_fields_of_study"
    many_to_many :classes, Class, join_through: "student_classes"
    has_many :student_classes, StudentClass
    has_many :student_assignments, through: [:student_classes, :student_assignments]
    has_many :schools, through: [:classes, :school]

    timestamps()
  end

  @req_fields [:name_first, :name_last, :phone,
              :notification_time, :notification_days_notice, :is_notifications,
              :is_mod_notifications, :is_reminder_notifications, :is_chat_notifications,
               :is_assign_post_notifications, :future_reminder_notification_time, :is_university]
  @opt_fields [:birthday, :gender, :organization, :bio, :grad_year]
  @all_fields @req_fields ++ @opt_fields

  @doc false
  def changeset(%Student{} = student, attrs) do
    student
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> validate_length(:grad_year, is: 4)
  end
end
