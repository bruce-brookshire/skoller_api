defmodule SkollerWeb.Api.V1.Class.WeightController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Classes.Weights
  alias SkollerWeb.Class.WeightView

  import SkollerWeb.Plugs.Auth
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class

  def index(conn, %{"class_id" => class_id}) do
    weights = Weights.get_class_weights(class_id)
    render(conn, WeightView, "index.json", weights: weights)
  end
end