defmodule SkollerWeb.Admin.ClassView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Admin.ClassView, as: AdminClassView
  alias SkollerWeb.ClassView, as: ClassView
  alias SkollerWeb.Admin.StudentClassView
  alias SkollerWeb.Admin.WeightView
  alias SkollerWeb.Admin.AssignmentView
  alias SkollerWeb.Class.NoteView
  
  def render("show.json", %{class: class}) do
    render_one(class, AdminClassView, "class.json")
  end

  def render("class.json", %{class: class}) do
    class = class |> Skoller.Repo.preload([:created_by_user, :updated_by_user])
    render_one(class, ClassView, "show.json")
    |> Map.merge(%{
      is_student_created: class.is_student_created,
      created_by: (if (class.created_by_user != nil), do: class.created_by_user.email, else: nil),
      updated_by: (if (class.updated_by_user != nil), do: class.updated_by_user.email, else: nil),
      created_on: class.created_on
    })
    |> Map.put(:notes, render_many(class.notes, NoteView, "note.json"))
    |> Map.put(:students, render_many(class.students, StudentClassView, "student_class.json"))
    |> Map.put(:weights, render_many(class.weights, WeightView, "weight.json"))
    |> Map.put(:assignments, render_many(class.assignments, AssignmentView, "assignment.json"))
  end
end