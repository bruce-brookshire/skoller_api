defmodule ClassnavapiWeb.Api.V1.Class.Change.TypeController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class.Change.Type
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.Change.TypeView
  
    def index(conn, %{}) do
      types = Repo.all(Type)
      render(conn, TypeView, "index.json", types: types)
    end
  end