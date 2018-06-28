defmodule SkollerWeb.MinClassView do
  use SkollerWeb, :view

  alias SkollerWeb.MinClassView

  def render("index.json", %{classes: classes}) do
      render_many(classes, MinClassView, "class.json", as: :class)
  end

  def render("class.json", %{class: %{class: class, professor: nil, class_period: period}}) do
    %{
        id: class.id,
        meet_days: class.meet_days,
        meet_start_time: class.meet_start_time,
        name: class.name,
        section: class.section,
        code: class.code,
        subject: class.subject,
        campus: class.campus,
        period_name: period.name,
        professor_name_first: nil,
        professor_name_last: nil
    }
  end

  def render("class.json", %{class: %{class: class, professor: professor, class_period: period}}) do
      %{
          id: class.id,
          meet_days: class.meet_days,
          meet_start_time: class.meet_start_time,
          name: class.name,
          section: class.section,
          code: class.code,
          subject: class.subject,
          campus: class.campus,
          period_name: period.name,
          professor_name_first: professor.name_first,
          professor_name_last: professor.name_last
      }
  end
end
