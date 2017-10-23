defmodule ClassnavapiWeb.Api.V1.Class.StatusController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class.Status
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.StatusView
  
    def index(conn, %{}) do
      statuses = Repo.all(Status)
      render(conn, StatusView, "index.json", statuses: statuses)
    end
  end