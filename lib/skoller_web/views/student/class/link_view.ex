defmodule SkollerWeb.Student.Class.LinkView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Student.Class.LinkView

  def render("show.json", %{link: link}) do
    render_one(link, LinkView, "link.json")
  end

  def render("link.json", %{link: link}) do
    %{
      class_name: link.class.name,
      student_name_first: link.student.name_first,
      student_name_last: link.student.name_last
    }
  end
end