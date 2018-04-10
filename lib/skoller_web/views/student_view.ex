defmodule SkollerWeb.StudentView do
  use SkollerWeb, :view

  alias SkollerWeb.StudentView
  alias Skoller.Repo
  alias SkollerWeb.School.FieldOfStudyView
  alias SkollerWeb.SchoolView
  alias SkollerWeb.UserView

  def render("index.json", %{students: students}) do
    render_many(students, StudentView, "student.json")
  end

  def render("show.json", %{student: student}) do
    render_one(student, StudentView, "student.json")
  end

  def render("student.json", %{student: student}) do
    student = student |> Repo.preload([:fields_of_study, :schools])
    %{
      id: student.id,
      name_first: student.name_first,
      name_last: student.name_last,
      phone: student.phone,
      birthday: student.birthday,
      gender: student.gender,
      is_verified: student.is_verified,
      is_notifications: student.is_notifications,
      is_mod_notifications: student.is_mod_notifications,
      is_reminder_notifications: student.is_reminder_notifications,
      is_chat_notifications: student.is_chat_notifications,
      is_assign_post_notifications: student.is_assign_post_notifications,
      notification_days_notice: student.notification_days_notice,
      notification_time: student.notification_time,
      future_reminder_notification_time: student.future_reminder_notification_time,
      organization: student.organization,
      bio: student.bio,
      grad_year: student.grad_year,
      schools: render_many(student.schools, SchoolView, "school.json"),
      fields_of_study: render_many(student.fields_of_study, FieldOfStudyView, "field.json", as: :field)
    }
  end

  def render("student-short.json", %{student: student}) do
    student = student |> Repo.preload(:users)
    %{
      id: student.id,
      name_first: student.name_first,
      name_last: student.name_last,
      organization: student.organization,
      bio: student.bio,
      users: render_many(student.users, UserView, "user.json")
    }
  end
end
