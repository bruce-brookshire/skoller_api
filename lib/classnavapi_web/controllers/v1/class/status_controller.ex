defmodule ClassnavapiWeb.Api.V1.Class.StatusController do
    use ClassnavapiWeb, :controller

    alias Classnavapi.Class.Status
    alias Classnavapi.Class
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.StatusView
    alias Classnavapi.Schools.School
    alias Classnavapi.ClassPeriod

    import Ecto.Query
    import ClassnavapiWeb.Helpers.AuthPlug
    
    @admin_role 200
    @syllabus_worker_role 300

    @needs_syllabus_status 200
    @complete_status 700
    @new_status 100
    @new_name "New Class"
    @maint_status 999
    @maint_name "Under Maintenance"
    
    plug :verify_role, %{roles: [@admin_role, @syllabus_worker_role]}

    def index(conn, %{}) do
      statuses = Repo.all(Status)
      render(conn, StatusView, "index.json", statuses: statuses)
    end

    def hub(conn, _params) do
      statuses = from(status in Status)
      |> join(:left, [status], class in Class, status.id == class.class_status_id)
      |> join(:left, [status, class], period in ClassPeriod, class.class_period_id == period.id)
      |> join(:left, [status, class, period], sch in School, sch.id == period.school_id and sch.is_auto_syllabus == true)
      |> where([status], status.id not in [@needs_syllabus_status, @complete_status])
      |> where([status, class], class.is_new_class == false)
      |> group_by([status, class, period, sch], [status.id, status.name, status.is_complete])
      |> select([status, class, period, sch], %{id: status.id, name: status.name, classes: count(class.id)})
      |> Repo.all()

      maint = from(class in Class)
      |> where([class], class.is_editable == false)
      |> select([class], %{id: @maint_status, name: @maint_name, classes: count(class.id)})
      |> Repo.all()

      new = from(class in Class)
      |> where([class], class.is_new_class == true and class.is_editable == true)
      |> select([class], %{id: @new_status, name: @new_name, classes: count(class.id)})
      |> Repo.all()

      statuses = statuses ++ maint ++ new

      render(conn, StatusView, "index.json", statuses: statuses)
    end
  end