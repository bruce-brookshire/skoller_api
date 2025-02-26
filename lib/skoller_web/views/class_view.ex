defmodule SkollerWeb.ClassView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.ClassView
  alias SkollerWeb.Class.StatusView
  alias SkollerWeb.ProfessorView
  alias SkollerWeb.Class.HelpRequestView
  alias SkollerWeb.Class.ChangeRequestView
  alias Skoller.Repo
  alias SkollerWeb.SchoolView
  alias SkollerWeb.Class.StudentRequestView
  alias Skoller.StudentClasses.StudentClass
  alias SkollerWeb.PeriodView
  alias Skoller.Schools

  import Ecto.Query

  def render("index.json", %{classes: classes}) do
    render_many(classes, ClassView, "class.json")
  end

  def render("show.json", %{class: class}) do
    render_one(class, ClassView, "class_detail.json")
  end

  # Made for 
  def render("class.json", %{
        class: %{
          class: class,
          professor: professor,
          class_period: class_period,
          enrollment: enrollment
        }
      }) do
    base_class_view(class)
    |> Map.merge(%{
      class_period: render_one(class_period, PeriodView, "period.json"),
      professor: render_one(professor, ProfessorView, "professor.json"),
      enrollment: enrollment
    })
  end

  def render("class.json", %{
        class: %{class: class, professor: professor, class_period: class_period}
      }) do
    base_class_view(class)
    |> Map.merge(%{
      class_period: render_one(class_period, PeriodView, "period.json"),
      professor: render_one(professor, ProfessorView, "professor.json")
    })
  end

  def render("class.json", %{class: %{class: class, professor: professor}}) do
    class = class |> Repo.preload(:class_period)

    base_class_view(class)
    |> Map.merge(%{
      class_period: render_one(class.class_period, PeriodView, "period.json"),
      professor: render_one(professor, ProfessorView, "professor.json")
    })
  end

  def render("class.json", %{class: class}) do
    class = class |> Repo.preload([:professor, :class_status, :class_period])

    base_class_view(class)
    |> Map.merge(%{
      class_period: render_one(class.class_period, PeriodView, "period.json"),
      professor: render_one(class.professor, ProfessorView, "professor.json"),
      status: render_one(class.class_status, StatusView, "status.json")
    })
  end

  def render("class_detail.json", %{class: class}) do
    class =
      class
      |> Repo.preload(
        [
          :class_status,
          :help_requests,
          :student_requests,
          change_requests: :class_change_request_members
        ],
        force: true
      )

    school = Schools.get_school_from_period(class.class_period_id)

    class
    |> render_one(ClassView, "class.json")
    |> Map.merge(%{
      school: render_one(school, SchoolView, "show.json"),
      status: render_one(class.class_status, StatusView, "status.json"),
      help_requests: render_many(class.help_requests, HelpRequestView, "help_request.json"),
      change_requests:
        render_many(class.change_requests, ChangeRequestView, "change_request.json"),
      student_requests:
        render_many(class.student_requests, StudentRequestView, "student_request.json"),
      enrollment: class |> get_class_enrollment()
    })
  end

  def render("class_short.json", %{class: class}) do
    %{
      id: class.id,
      name: class.name,
      section: class.section,
      code: class.code,
      subject: class.subject,
      is_editable: class.is_editable,
      campus: class.campus,
      class_period_id: class.class_period_id
    }
  end

  defp base_class_view(class) do
    %{
      id: class.id,
      credits: class.credits,
      crn: class.crn,
      grade_scale: class.grade_scale,
      location: class.location,
      meet_days: class.meet_days,
      meet_end_time: class.meet_end_time,
      meet_start_time: class.meet_start_time,
      name: class.name,
      section: class.section,
      code: class.code,
      subject: class.subject,
      seat_count: class.seat_count,
      is_editable: class.is_editable,
      is_syllabus: class.is_syllabus,
      is_points: class.is_points,
      is_chat_enabled: class.is_chat_enabled,
      is_assignment_posts_enabled: class.is_assignment_posts_enabled,
      type: class.class_type,
      campus: class.campus
    }
  end

  defp get_class_enrollment(class) do
    from(sc in StudentClass)
    |> where([sc], sc.class_id == ^class.id and sc.is_dropped == false)
    |> Repo.aggregate(:count, :id)
  end
end
