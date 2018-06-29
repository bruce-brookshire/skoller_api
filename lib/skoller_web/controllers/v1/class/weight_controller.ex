defmodule SkollerWeb.Api.V1.Class.WeightController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Weights.Weight
  alias Skoller.Repo
  alias SkollerWeb.Class.WeightView

  import Ecto.Query
  import SkollerWeb.Plugs.Auth
  
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