defmodule SkollerWeb.Student.Class.LinkView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Student.Class.LinkView

  def render("show.json", %{link: link}) do
    render_one(link, LinkView, "link.json")
  end

  def render("link.json", %{link: link}) do
    student = link.student |> Skoller.Repo.preload([:users])
    %{
      class_name: link.class.name,
      student_name_first: student.name_first,
      student_name_last: student.name_last,
      student_image_path: (student.users |> List.first).pic_path
    }
  end
end
