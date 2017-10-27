defmodule ClassnavapiWeb.AssignmentView do
    use ClassnavapiWeb, :view

    alias ClassnavapiWeb.AssignmentView

    def render("index.json", %{assignments: assignments}) do
        render_many(assignments, AssignmentView, "assignment.json")
    end

    def render("show.json", %{assignment: assignment}) do
        render_one(assignment, AssignmentView, "assignment.json")
    end

    def render("assignment.json", %{assignment: assignment}) do
        %{
            due: assignment.due,
            name: assignment.name,
            weight_id: assignment.weight_id
        }
    end
end
  