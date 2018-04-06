defmodule SkollerWeb.AssignmentView do
    use SkollerWeb, :view

    alias SkollerWeb.AssignmentView
    alias Skoller.Repo

    def render("index.json", %{assignments: assignments}) do
        render_many(assignments, AssignmentView, "assignment.json")
    end

    def render("show.json", %{assignment: assignment}) do
        render_one(assignment, AssignmentView, "assignment.json")
    end

    def render("assignment.json", %{assignment: %{relative_weight: weight} = assignment}) do
        assignment = assignment |> Repo.preload(:posts)
        %{
            id: assignment.id,
            due: assignment.due,
            name: assignment.name,
            weight_id: assignment.weight_id,
            weight: Decimal.to_float(weight),
            posts: render_many(assignment.posts, SkollerWeb.Assignment.PostView, "post.json")
        }
    end

    def render("assignment.json", %{assignment: assignment}) do
        assignment = assignment |> Repo.preload(:posts)
        %{
            id: assignment.id,
            due: assignment.due,
            name: assignment.name,
            weight_id: assignment.weight_id,
            inserted_at: assignment.inserted_at,
            posts: render_many(assignment.posts, SkollerWeb.Assignment.PostView, "post.json")
        }
    end

    def render("assignment-short.json", %{assignment: assignment}) do
        %{
            id: assignment.id,
            due: assignment.due,
            name: assignment.name,
            weight_id: assignment.weight_id,
            inserted_at: assignment.inserted_at
        }
    end
end
