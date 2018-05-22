defmodule SkollerWeb.Admin.ClassView do
  use SkollerWeb, :view

  alias SkollerWeb.Admin.ClassView, as: AdminClassView
  alias SkollerWeb.ClassView, as: ClassView
  alias SkollerWeb.Class.StudentClassView
  
  def render("show.json", %{class: class}) do
    render_one(class, AdminClassView, "class.json")
  end

  def render("class.json", %{class: class}) do
    render_one(class, ClassView, "show.json")
    |> Map.put(:students, render_many(class.students, StudentClassView, "student_class-admin.json"))
  end
end