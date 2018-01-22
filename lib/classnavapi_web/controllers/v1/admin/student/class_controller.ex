defmodule ClassnavapiWeb.Api.V1.Admin.Student.ClassController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentClassView
  alias ClassnavapiWeb.Helpers.ClassCalcs
  alias ClassnavapiWeb.Helpers.ModHelper

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  
  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :student
  plug :verify_member, %{of: :school, using: :class_id}
  plug :verify_member, %{of: :class, using: :id}
  plug :verify_class_is_editable, :class_id

  def index(conn, %{"student_id" => student_id}) do
    query = from(classes in StudentClass)
    student_classes = query
                      |> where([classes], classes.student_id == ^student_id and classes.is_dropped == false)
                      |> Repo.all()
                      |> Repo.preload(:class)
                      |> Enum.map(&Map.put(&1, :grade, ClassCalcs.get_class_grade(&1.id)))
                      |> Enum.map(&Map.put(&1, :completion, ClassCalcs.get_class_completion(&1)))
                      |> Enum.map(&Map.put(&1, :enrollment, ClassCalcs.get_enrollment(&1.class)))
                      |> Enum.map(&Map.put(&1, :new_assignments, get_new_class_assignments(&1)))

    render(conn, StudentClassView, "index.json", student_classes: student_classes)
  end

  defp get_new_class_assignments(%StudentClass{} = student_class) do
    student_class |> ModHelper.get_new_assignment_mods()
  end
end