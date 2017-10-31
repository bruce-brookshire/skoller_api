defmodule ClassnavapiWeb.Api.V1.Class.StatusController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class.Status
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.StatusView, as: ClassStatusView
    alias ClassnavapiWeb.Hub.Class.StatusView, as: HubStatusView

    import Ecto.Query
  
    def index(conn, %{}) do
      statuses = Repo.all(Status)
      render(conn, ClassStatusView, "index.json", statuses: statuses)
    end

    defp get_class_count_by_status(status) do
      classes = Repo.all(from class in Classnavapi.Class, where: class.class_status_id == ^status.id)

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

      render(conn, HubStatusView, "index.json", statuses: statuses)
    end
  end