defmodule SkollerWeb.Admin.AssignmentView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Repo

  def render("assignment.json", %{assignment: %{assignment: item}}) do
    assignment = item.assignment |> Repo.preload([:posts, :created_by_user, :updated_by_user])
    %{
        id: assignment.id,
        due: assignment.due,
        name: assignment.name,
        weight_id: assignment.weight_id,
        inserted_at: assignment.inserted_at,
        posts: render_many(assignment.posts, SkollerWeb.Assignment.PostView, "post.json"),
        from_mod: assignment.from_mod,
        student_count: item.student_count,
        mod_count: item.mod_count,
        created_by: (if (assignment.created_by_user != nil), do: assignment.created_by_user.email, else: nil),
        updated_by: (if (assignment.updated_by_user != nil), do: assignment.updated_by_user.email, else: nil)
    }
  end
end