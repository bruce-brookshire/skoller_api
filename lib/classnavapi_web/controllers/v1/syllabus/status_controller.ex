defmodule ClassnavapiWeb.Api.V1.Syllabus.StatusController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Syllabus.Status
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Syllabus.StatusView
  
    def index(conn, %{}) do
      statuses = Repo.all(Status)
      render(conn, StatusView, "index.json", statuses: statuses)
    end
  end