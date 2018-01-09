defmodule ClassnavapiWeb.AssignmentView do
    use ClassnavapiWeb, :view

    alias ClassnavapiWeb.AssignmentView

    def render("index.json", %{assignments: assignments}) do
        render_many(assignments, AssignmentView, "assignment.json")
    end

    def render("show.json", %{assignment: assignment}) do
        render_one(assignment, AssignmentView, "assignment.json")
    end

    def render("assignment.json", %{assignment: %{relative_weight: weight} = assignment}) do
        %{
            id: assignment.id,
            due: assignment.due,
            name: assignment.name,
            weight_id: assignment.weight_id,
            weight: Decimal.to_float(weight)
        }
    end

    def render("assignment.json", %{assignment: assignment}) do
        %{
            id: assignment.id,
            due: assignment.due,
            name: assignment.name,
            weight_id: assignment.weight_id,
            inserted_at: assignment.inserted_at
        }
    end
end
