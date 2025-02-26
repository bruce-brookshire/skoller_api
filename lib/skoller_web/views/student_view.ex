defmodule SkollerWeb.StudentView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.StudentView
  alias Skoller.Repo
  alias SkollerWeb.School.FieldOfStudyView
  alias SkollerWeb.SchoolView
  alias SkollerWeb.PeriodView
  alias SkollerWeb.UserView

  @signup_path "/s/"

  def render("index.json", %{students: students}) do
    render_many(students, StudentView, "student.json")
  end

  def render("show.json", %{student: student}) do
    render_one(student, StudentView, "student.json")
  end

  def render("show.json", %{link: student}) do
    render_one(student, StudentView, "link.json")
  end

  def render("link.json", %{student: student}) do
    student = student |> Repo.preload([:user])

    %{
      student_id: student.id,
      student_name_first: student.name_first,
      student_name_last: student.name_last,
      student_image_path: student.user.pic_path
    }
  end

  # TODO: remove is_verified once new app has been adopted
  def render("student.json", %{student: student}) do
    student =
      student
      |> Repo.preload([
        :fields_of_study,
        :schools,
        :primary_school,
        :primary_organization,
        :primary_period,
        :degree_type
      ])

    raise_effort = Skoller.Students.get_org_raise_effort_for_student(student)

    %{
      id: student.id,
      name_first: student.name_first,
      name_last: student.name_last,
      phone: student.phone,
      birthday: student.birthday,
      gender: student.gender,
      is_notifications: student.is_notifications,
      is_verified: true,
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
      enrollment_link: System.get_env("WEB_URL") <> @signup_path <> student.enrollment_link,
      schools: render_many(student.schools, SchoolView, "show.json"),
      fields_of_study:
        render_many(student.fields_of_study, FieldOfStudyView, "field.json", as: :field),
      points: Skoller.StudentPoints.get_points_by_student_id(student.id),
      raise_effort: raise_effort,
      primary_school: render_one(student.primary_school, SchoolView, "show.json"),
      primary_period: render_one(student.primary_period, PeriodView, "period.json"),
      primary_organization: student |> primary_organization_name(),
      todo_days_future: student.todo_days_future,
      todo_days_past: student.todo_days_past,
      degree_type: student.degree_type |> render_degree_type()
    }
  end

  def render("student-short.json", %{student: student}) do
    student = student |> Repo.preload(:user)

    %{
      id: student.id,
      name_first: student.name_first,
      name_last: student.name_last,
      organization: student.organization,
      bio: student.bio,
      points: Skoller.StudentPoints.get_points_by_student_id(student.id),
      user: render_one(student.user, UserView, "user.json")
    }
  end

  def render("venmo_handle.json", %{student: student}) do
    %{student: student}
  end

  def render("venmo_handle.json", %{changeset: %Ecto.Changeset{} = changeset}) do
    %{errors: changeset.errors}
  end

  defp primary_organization_name(%{primary_organization: primary_organization})
       when not is_nil(primary_organization) do
    primary_organization.name
  end

  defp primary_organization_name(_student), do: nil

  defp render_degree_type(nil), do: nil
  defp render_degree_type(%{} = degree), do: Map.take(degree, [:id, :name])
end
