defmodule Skoller.Repo.Migrations.CreateSchools do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :name, :string
      add :adr_line_1, :string
      add :adr_line_2, :string
      add :adr_city, :string
      add :adr_state, :string
      add :adr_zip, :string
      add :timezone, :string
      add :is_active_enrollment, :boolean, default: true, null: false
      add :is_readonly, :boolean, default: false, null: false
      add :is_diy_enabled, :boolean, default: true, null: false
      add :is_diy_preferred, :boolean, default: false, null: false
      add :is_auto_syllabus, :boolean, default: true, null: false
      add :short_name, :string

      timestamps()
    end

    create unique_index(:schools, [:short_name])

    flush()

    create table(:fields_of_study) do
      add :field, :string
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:fields_of_study, [:school_id])
    create unique_index(:fields_of_study, [:field, :school_id])

    create table(:students) do
      add :name_first, :string
      add :name_last, :string
      add :phone, :string
      add :birthday, :date
      add :gender, :string
      add :school_id, references(:schools)
      add :verification_code, :string
      add :is_verified, :boolean, default: false, null: false
      add :notification_time, :time
      add :notification_days_notice, :int
      add :is_notifications, :boolean, default: true, null: false
      add :is_mod_notifications, :boolean, default: true, null: false
      add :is_reminder_notifications, :boolean, default: true, null: false
      add :is_chat_notifications, :boolean, default: true, null: false
      add :bio, :string
      add :organization, :string

      timestamps()
    end

    create index(:students, [:school_id])

    flush()

    create table(:users) do
      add :email, :string
      add :password_hash, :string
      add :student_id, references(:students)
      add :pic_path, :string
      add :is_active, :boolean, default: true

      timestamps()
    end

    create unique_index(:users, :email)

    create table(:roles, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:roles, [:name])

    flush()

    create table(:user_roles) do
      add :user_id, references(:users, on_delete: :nothing)
      add :role_id, references(:roles, on_delete: :nothing)

      timestamps()
    end

    create index(:user_roles, [:user_id])
    create index(:user_roles, [:role_id])
    create unique_index(:user_roles, [:user_id, :role_id])

    create table(:class_periods) do
      add :name, :string
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:class_periods, [:school_id])

    flush()

    create table(:professors) do
      add :name_first, :string
      add :name_last, :string
      add :email, :string
      add :phone, :string
      add :office_location, :string
      add :office_availability, :string
      add :class_period_id, references(:class_periods, on_delete: :nothing)

      timestamps()
    end

    create index(:professors, [:class_period_id])

    create table(:email_domains) do
      add :email_domain, :string
      add :is_professor_only, :boolean
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:email_domains, [:school_id])

    create table(:class_statuses, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string
      add :is_complete, :boolean, null: false

      timestamps()
    end

    create unique_index(:class_statuses, [:name])

    flush()

    create table(:classes) do
      add :name, :string
      add :number, :string
      add :crn, :string
      add :credits, :string
      add :location, :string
      add :meet_days, :string
      add :grade_scale, :string
      add :meet_start_time, :string
      add :meet_end_time, :string
      add :seat_count, :integer
      add :class_start, :utc_datetime
      add :class_end, :utc_datetime
      add :class_type, :string
      add :campus, :string
      add :is_ghost, :boolean, default: false, null: false
      add :is_enrollable, :boolean, default: false, null: false
      add :is_editable, :boolean, default: false, null: false
      add :is_syllabus, :boolean, default: false, null: false
      add :is_points, :boolean, default: false, null: false
      add :professor_id, references(:professors, on_delete: :nothing)
      add :class_period_id, references(:class_periods, on_delete: :nothing)
      add :class_status_id, references(:class_statuses, on_delete: :nothing)
      add :class_upload_key, :string

      timestamps()
    end

    create index(:classes, [:professor_id])
    create index(:classes, [:class_period_id])
    create index(:classes, [:class_status_id])

    create table(:docs) do
      add :path, :string
      add :is_syllabus, :boolean, default: false, null: false
      add :class_id, references(:classes, on_delete: :nothing)
      add :name, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:docs, [:class_id])

    create table(:student_classes) do
      add :student_id, references(:students, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)
      add :color, :string
      add :is_notifications, :boolean, default: true, null: false
      add :is_dropped, :boolean, default: false, null: false

      timestamps()
    end

    create index(:student_classes, [:student_id])
    create index(:student_classes, [:class_id])
    create unique_index(:student_classes, [:student_id, :class_id])

    create table(:class_weights) do
      add :name, :string
      add :weight, :decimal
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:class_weights, [:class_id])

    create table(:assignments) do
      add :name, :string
      add :due, :utc_datetime
      add :weight_id, references(:class_weights, on_delete: :nilify_all)
      add :class_id, references(:classes, on_delete: :nothing)
      add :from_mod, :boolean, default: false, null: false

      timestamps()
    end

    create index(:assignments, [:class_id])
    create index(:assignments, [:weight_id])

    create table(:student_assignments) do
      add :name, :string
      add :due, :utc_datetime
      add :weight_id, references(:class_weights, on_delete: :nilify_all)
      add :student_class_id, references(:student_classes, on_delete: :nothing)
      add :assignment_id, references(:assignments, on_delete: :delete_all)
      add :grade, :decimal
      add :is_completed, :boolean, default: false, null: false
      add :is_notifications, :boolean, default: true, null: false
      add :notes, :string, size: 2000

      timestamps()
    end

    create index(:student_assignments, [:student_class_id])
    create index(:student_assignments, [:weight_id])
    create index(:student_assignments, [:assignment_id])

    create table(:class_help_types, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:class_help_types, [:name])

    create table(:class_help_requests) do
      add :note, :string
      add :is_completed, :boolean, default: false, null: false
      add :class_id, references(:classes, on_delete: :nothing)
      add :class_help_type_id, references(:class_help_types, on_delete: :nothing)

      timestamps()
    end

    create index(:class_help_requests, [:class_id])
    create index(:class_help_requests, [:class_help_type_id])

    create table(:class_change_types, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:class_change_types, [:name])

    create table(:class_change_requests) do
      add :note, :string
      add :is_completed, :boolean, default: false, null: false
      add :class_id, references(:classes, on_delete: :nothing)
      add :class_change_type_id, references(:class_change_types, on_delete: :nothing)
      add :data, :map
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:class_change_requests, [:class_id])
    create index(:class_change_requests, [:class_change_type_id])
    create index(:class_change_requests, [:user_id])

    create table(:student_fields_of_study) do
      add :field_of_study_id, references(:fields_of_study, on_delete: :nothing)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:student_fields_of_study, [:field_of_study_id])
    create index(:student_fields_of_study, [:student_id])
    create unique_index(:student_fields_of_study, [:field_of_study_id, :student_id])

    create table(:assignment_mod_types, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string

      timestamps()
    end

    create unique_index(:assignment_mod_types, [:name])

    create table(:assignment_modifications) do
      add :data, :map
      add :is_private, :boolean, default: false, null: false
      add :assignment_id, references(:assignments, on_delete: :delete_all)
      add :assignment_mod_type_id, references(:assignment_mod_types, on_delete: :nothing)
      add :student_id, references(:students, on_delete: :nothing)
      add :is_auto_update, :boolean, default: false, null: false

      timestamps()
    end

    create index(:assignment_modifications, [:assignment_id])
    create index(:assignment_modifications, [:assignment_mod_type_id])
    create index(:assignment_modifications, [:student_id])
    create unique_index(:student_assignments, [:student_class_id, :assignment_id])

    create table(:modification_actions) do
      add :is_accepted, :boolean, null: true
      add :assignment_modification_id, references(:assignment_modifications, on_delete: :delete_all)
      add :student_class_id, references(:student_classes, on_delete: :nothing)
      add :is_manual, :boolean, default: false, null: false

      timestamps()
    end

    create index(:modification_actions, [:assignment_modification_id])
    create index(:modification_actions, [:student_class_id])
    create unique_index(:modification_actions, [:assignment_modification_id, :student_class_id])

    create table(:user_devices) do
      add :udid, :string
      add :type, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:user_devices, [:user_id])
    create unique_index(:user_devices, [:user_id, :udid])

    create table(:class_lock_sections) do
      add :name, :string
      add :is_diy, :boolean, default: true, null: false

      timestamps()
    end

    create table(:class_locks) do
      add :is_completed, :boolean, default: false, null: false
      add :class_lock_section_id, references(:class_lock_sections, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:class_locks, [:class_lock_section_id])
    create index(:class_locks, [:class_id])
    create index(:class_locks, [:user_id])
    create unique_index(:class_locks, [:class_id, :class_lock_section_id])

    create table(:class_abandoned_locks) do
      add :class_lock_section_id, references(:class_lock_sections, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:class_abandoned_locks, [:class_lock_section_id])
    create index(:class_abandoned_locks, [:class_id])
    create index(:class_abandoned_locks, [:user_id])

    create unique_index(:classes, [:class_period_id, 
                                  :professor_id,
                                  :campus,
                                  :name,
                                  :number,
                                  :meet_days,
                                  :meet_end_time,
                                  :meet_start_time], name: :unique_class_index)

    create table(:csv_uploads) do
      add :name, :string

      timestamps()
    end

    create unique_index(:csv_uploads, [:name], name: :csv_unique_index)

    create table(:class_student_request_types) do
      add :name, :string

      timestamps()
    end

    create table(:class_student_requests) do
      add :notes, :string
      add :is_completed, :boolean, default: false, null: false
      add :class_student_request_type_id, references(:class_student_request_types, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:class_student_requests, [:class_student_request_type_id])
    create index(:class_student_requests, [:class_id])

    create table(:class_student_request_docs) do
      add :class_student_request_id, references(:class_student_requests, on_delete: :nothing)
      add :doc_id, references(:docs, on_delete: :delete_all)

      timestamps()
    end

    create index(:class_student_request_docs, [:class_student_request_id])
    create index(:class_student_request_docs, [:doc_id])

    create table(:chat_algorithms) do
      add :name, :string

      timestamps()
    end
  end
end
