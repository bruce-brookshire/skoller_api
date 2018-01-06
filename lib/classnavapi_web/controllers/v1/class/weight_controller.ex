defmodule ClassnavapiWeb.Api.V1.Class.WeightController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class.Weight
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.WeightView

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class

  def index(conn, %{"class_id" => class_id}) do
    weights = Repo.all(from a in Weight, where: a.class_id == ^class_id)
    render(conn, WeightView, "index.json", weights: weights)
  end
end