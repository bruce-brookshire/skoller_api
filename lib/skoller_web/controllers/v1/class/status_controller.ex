defmodule SkollerWeb.Api.V1.Class.StatusController do
    use SkollerWeb, :controller

    alias Skoller.Class.Status
    alias Skoller.Schools.Class
    alias Skoller.Repo
    alias SkollerWeb.Class.StatusView
    alias Skoller.Schools.School
    alias Skoller.Schools.ClassPeriod
    alias Skoller.Classes

    import Ecto.Query
    import SkollerWeb.Helpers.AuthPlug
    
    @admin_role 200
    @syllabus_worker_role 300

    @needs_syllabus_status 200
    @complete_status 700
    @maint_status 999
    @maint_name "Under Maintenance"
    
    plug :verify_role, %{roles: [@admin_role, @syllabus_worker_role]}

    def index(conn, %{}) do
      statuses = Repo.all(Status)
      render(conn, StatusView, "index.json", statuses: statuses)
    end

    def hub(conn, _params) do
      statuses = Classes.get_class_status_counts()

      render(conn, StatusView, "index.json", statuses: statuses)
    end
  end