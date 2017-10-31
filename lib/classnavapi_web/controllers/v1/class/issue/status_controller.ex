defmodule ClassnavapiWeb.Api.V1.Class.Issue.StatusController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class.Issue.Status
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.Issue.StatusView
  
    def index(conn, %{}) do
      statuses = Repo.all(Status)
      render(conn, StatusView, "index.json", statuses: statuses)
    end
  end