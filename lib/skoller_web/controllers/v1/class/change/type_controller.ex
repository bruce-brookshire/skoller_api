defmodule SkollerWeb.Api.V1.Class.Change.TypeController do
    use SkollerWeb, :controller
    
    alias Skoller.Class.Change.Type
    alias Skoller.Repo
    alias SkollerWeb.Class.Change.TypeView
  
    def index(conn, %{}) do
      types = Repo.all(Type)
      render(conn, TypeView, "index.json", types: types)
    end
  end