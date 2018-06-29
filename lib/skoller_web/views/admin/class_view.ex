defmodule SkollerWeb.Admin.ClassView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Admin.ClassView, as: AdminClassView
  alias SkollerWeb.ClassView, as: ClassView
  alias SkollerWeb.Admin.StudentClassView
  alias SkollerWeb.Class.WeightView
  alias SkollerWeb.Admin.AssignmentView
  
  def render("show.json", %{class: class}) do
    render_one(class, AdminClassView, "class.json")
  end

  def render("class.json", %{class: class}) do
    render_one(class, ClassView, "show.json")
    |> Map.put(:students, render_many(class.students, StudentClassView, "student_class.json"))
    |> Map.put(:weights, render_many(class.weights, WeightView, "weight.json"))
    |> Map.put(:assignments, render_many(class.assignments, AssignmentView, "assignment.json"))
  end
end