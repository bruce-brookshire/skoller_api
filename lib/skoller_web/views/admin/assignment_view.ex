defmodule SkollerWeb.Admin.AssignmentView do
  use SkollerWeb, :view

  alias Skoller.Repo

  def render("assignment.json", %{assignment: %{assignment: item}}) do
    assignment = item.assignment |> Repo.preload(:posts)
    %{
        id: assignment.id,
        due: assignment.due,
        name: assignment.name,
        weight_id: assignment.weight_id,
        inserted_at: assignment.inserted_at,
        posts: render_many(assignment.posts, SkollerWeb.Assignment.PostView, "post.json"),
        from_mod: assignment.from_mod,
        student_count: item.student_count,
        mod_count: item.mod_count
    }
  end
end