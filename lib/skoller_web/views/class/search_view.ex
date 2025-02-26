defmodule SkollerWeb.Class.SearchView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Class.SearchView
  alias SkollerWeb.ProfessorView
  alias Skoller.ClassStatuses.Classes

  def render("index.json", %{classes: classes}) do
    render_many(classes, SearchView, "class.json", as: :class)
  end

  def render("class.json", %{class: %{class: class, class_period: class_period, professor: professor, school: school, class_status: class_status, enroll: enroll}}) do
    %{
      id: class.id,
      premium: class.premium,
      trial: class.trial,
      expired: class.expired,
      received: class.received,
      days_left: Skoller.Periods.days_left(class_period),
      meet_days: class.meet_days,
      meet_start_time: class.meet_start_time,
      name: class.name,
      section: class.section,
      code: class.code,
      subject: class.subject,
      enrolled: get_enrolled(enroll.count),
      campus: class.campus,
      professor: render_one(professor, ProfessorView, "professor-short.json"),
      school: %{
        id: school.id,
        name: school.name
      },
      status: Classes.get_class_status(class_status),
      period_name: class_period.name
    }
  end

  defp get_enrolled(nil), do: 0
  defp get_enrolled(val), do: val
end
  