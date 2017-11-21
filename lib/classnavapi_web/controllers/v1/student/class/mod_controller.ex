defmodule ClassnavapiWeb.Api.V1.Student.Class.ModController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Helpers.ModHelper
  alias ClassnavapiWeb.AssignmentView

  def index(conn, %{"class_id" => class_id, "student_id" => student_id}) do
    student_class = Repo.get_by!(StudentClass, student_id: student_id, class_id: class_id)

    assignments = student_class |> ModHelper.get_new_assignment_mods()

    render(conn, AssignmentView, "index.json", assignments: assignments)
  end
end