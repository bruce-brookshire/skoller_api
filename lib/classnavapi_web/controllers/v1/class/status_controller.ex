defmodule ClassnavapiWeb.Api.V1.Class.StatusController do
    use ClassnavapiWeb, :controller

    alias Classnavapi.Class.Status
    alias Classnavapi.Class
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.StatusView
    alias ClassnavapiWeb.ClassView
    alias Classnavapi.School
    alias Classnavapi.ClassPeriod

    import Ecto.Query
    import ClassnavapiWeb.Helpers.AuthPlug
    
    @admin_role 200
    
    plug :verify_role, %{role: @admin_role}

    def index(conn, %{}) do
      statuses = Repo.all(Status)
      render(conn, StatusView, "index.json", statuses: statuses)
    end

    def update(conn, %{"class_id" => class_id, "class_status_id" => id}) do
      class = Repo.get!(Class, class_id)

      results = class
      |> Ecto.Changeset.change(%{class_status_id: id})
      |> Repo.update()

      case results do
        {:ok, class} ->
          render(conn, ClassView, "show.json", class: class)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
      end
    end

    defp get_class_count_by_status(status) do
      classes = (from class in Class)
      |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
      |> join(:inner, [class, period], sch in School, sch.id == period.school_id)
      |> where([class], class.class_status_id == ^status.id)
      |> where([class, period, sch], sch.is_auto_syllabus == true)
      |> Repo.all()

      classes
      |> Enum.count(& &1)
    end

    defp put_class_status_counts(statuses) do
      statuses 
      |> Enum.map(&Map.put(&1, :classes, get_class_count_by_status(&1)))
    end

    def hub(conn, %{}) do
      statuses = Repo.all(Status)

      statuses = statuses |> put_class_status_counts

      render(conn, StatusView, "index.json", statuses: statuses)
    end
  end