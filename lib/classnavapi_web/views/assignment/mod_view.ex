defmodule ClassnavapiWeb.Assignment.ModView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Assignment.ModView
  alias ClassnavapiWeb.ClassView
  alias Classnavapi.Repo

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

  def render("index.json", %{mods: mods}) do
    render_many(mods, ModView, "mod.json")
  end

  def render("show.json", %{mod: mod}) do
    render_one(mod, ModView, "mod.json")
  end

  def render("mod.json", %{mod: %{mod: mod, action: action, student_assignment: student_assignment}}) do
    mod = mod |> Repo.preload([:assignment_mod_type, :assignment])
    assignment = mod.assignment |> Repo.preload(:class)
    %{
      id: mod.id,
      data: mod.data,
      mod_type: mod.assignment_mod_type.name,
      short_msg: assignment.name <> " " <> mod_type(mod) <> ".",
      class: render_one(assignment.class, ClassView, "class.json"),
      is_accepted: action.is_accepted,
      student_assignment_id: get_student_assignment_id(student_assignment)
    }
  end

  def render("mod.json", %{mod: mod}) do
    mod = mod |> Repo.preload(:assignment_mod_type)
    %{
      id: mod.id,
      data: mod.data,
      mod_type: mod.assignment_mod_type.name
    }
  end

  defp get_student_assignment_id(nil), do: nil
  defp get_student_assignment_id(student_assignment), do: student_assignment.id

  defp mod_type(mod) do
    case mod.assignment_mod_type_id do
      @name_assignment_mod -> "name changed"
      @due_assignment_mod -> "due date changed"
      @weight_assignment_mod -> "weight changed"
      @new_assignment_mod -> "added"
      @delete_assignment_mod -> "deleted"
    end
  end
end
