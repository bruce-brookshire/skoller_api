defmodule Classnavapi.Student do

  @moduledoc """

  Defines the schema and changeset for students

  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Classnavapi.Student

  schema "students" do
    field :birthday, :date
    field :gender, :string
    field :name_first, :string
    field :name_last, :string
    field :phone, :string
    field :verification_code, :string
    field :is_verified, :boolean
    field :school_id, :id
    field :notification_time, :time
    field :notification_days_notice, :integer, default: 1
    field :is_notifications, :boolean, default: true
    has_many :users, Classnavapi.User
    many_to_many :fields_of_study, Classnavapi.School.FieldOfStudy, join_through: "student_fields_of_study"
    belongs_to :school, Classnavapi.School, define_field: false
    many_to_many :classes, Classnavapi.Class, join_through: "student_classes"
    has_many :student_classes, Classnavapi.Class.StudentClass
    has_many :student_assignments, through: [:student_classes, :student_assignments]

    timestamps()
  end

  @req_fields [:name_first, :name_last, :phone, :birthday, :gender,
              :school_id, :notification_time, :notification_days_notice, :is_notifications]
  @all_fields @req_fields

  @doc false
  def changeset(%Student{} = student, attrs) do

    student
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
    |> foreign_key_constraint(:school_id)
  end
end
