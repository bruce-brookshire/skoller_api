defmodule SkollerWeb.Api.V1.Class.StatusController do
  use SkollerWeb, :controller

  alias SkollerWeb.Class.StatusView
  alias Skoller.Classes

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@admin_role, @syllabus_worker_role]}

  def index(conn, %{}) do
    statuses = Classes.get_statuses()
    render(conn, StatusView, "index.json", statuses: statuses)
  end

  def hub(conn, _params) do
    statuses = Classes.get_class_status_counts()
    render(conn, StatusView, "index.json", statuses: statuses)
  end
end