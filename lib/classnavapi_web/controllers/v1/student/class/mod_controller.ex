defmodule ClassnavapiWeb.Api.V1.Student.ModController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Assignment.Mod
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentAssignmentView
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.Helpers.ModHelper

  def create(conn, %{"student_id" => student_id, "id" => id} = params) do

    mod = Mod
    |> Repo.get!(id)
    |> Repo.preload(:assignment)

    student_class = Repo.get_by!(StudentClass, class_id: mod.assignment.class_id, student_id: student_id)

    case Repo.transaction(ModHelper.apply_mod(mod, student_class)) do
      {:ok, %{student_assignment: student_assignment}} ->
        conn
        |> render(StudentAssignmentView, "show.json", student_assignment: student_assignment)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end
end