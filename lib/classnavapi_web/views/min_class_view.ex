defmodule ClassnavapiWeb.MinClassView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.MinClassView

  def render("index.json", %{classes: classes}) do
      render_many(classes, MinClassView, "class.json", as: :class)
  end

  def render("class.json", %{class: %{class: class, professor: nil}}) do
    %{
        id: class.id,
        meet_days: class.meet_days,
        meet_start_time: class.meet_start_time,
        name: class.name,
        number: class.number,
        campus: class.campus,
        class_period_id: class.class_period_id,
        professor_name_first: nil,
        professor_name_last: nil
    }
  end

  def render("class.json", %{class: %{class: class, professor: professor}}) do
      %{
          id: class.id,
          meet_days: class.meet_days,
          meet_start_time: class.meet_start_time,
          name: class.name,
          number: class.number,
          campus: class.campus,
          class_period_id: class.class_period_id,
          professor_name_first: professor.name_first,
          professor_name_last: professor.name_last
      }
  end
end
