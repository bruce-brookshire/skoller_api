defmodule ClassnavapiWeb.Api.V1.Class.Help.TypeController do
    use ClassnavapiWeb, :controller
    
    alias Classnavapi.Class.Help.Type
    alias Classnavapi.Repo
    alias ClassnavapiWeb.Class.Help.TypeView
  
    def index(conn, %{}) do
      types = Repo.all(Type)
      render(conn, TypeView, "index.json", types: types)
    end
  end