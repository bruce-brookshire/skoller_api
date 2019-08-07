defmodule SkollerWeb.Student.Class.LinkView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Student.Class.LinkView
  alias SkollerWeb.ClassView

  def render("show.json", %{link: link}) do
    render_one(link, LinkView, "link.json")
  end

  def render("link.json", %{link: %{class: student_class} = link}) do
    student = link.student |> Skoller.Repo.preload([:users])
    IO.inspect student_class

    %{
      student_name_first: student.name_first,
      student_name_last: student.name_last,
      student_image_path: (student.users |> List.first()).pic_path,
      student_class: render_one(student_class, ClassView, "show.json")
    }
  end
end
