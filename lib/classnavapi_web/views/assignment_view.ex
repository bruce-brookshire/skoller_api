defmodule ClassnavapiWeb.AssignmentView do
    use ClassnavapiWeb, :view

    import Ecto.Query

    alias ClassnavapiWeb.AssignmentView
    alias Classnavapi.Repo

    def render("index.json", %{assignments: assignments}) do
        render_many(assignments, AssignmentView, "assignment.json")
    end

    def render("show.json", %{assignment: assignment}) do
        render_one(assignment, AssignmentView, "assignment.json")
    end

    def render("assignment.json", %{assignment: assignment}) do
        assignment = assignment |> get_weight_ratio()

        %{
            due: assignment.due,
            name: assignment.name,
            weight_id: assignment.weight_id,
            worth: assignment.worth
        }
    end

    defp get_weight_ratio(assignment) do
        weight = Repo.get!(Classnavapi.Class.Weight, assignment.weight_id)
        assignments = Repo.all(from a in Classnavapi.Class.Assignment, where: a.class_id == ^assignment.class_id and a.weight_id == ^Map.get(weight, :id))
        assignment_count = assignments |> Enum.count(& &1)
        Map.put(assignment, :worth, Decimal.div(Map.get(weight, :weight), Decimal.new(assignment_count)))
    end
end
  