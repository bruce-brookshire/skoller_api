defmodule ClassnavapiWeb.Api.V1.Class.StudentRequest.TypeController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Class.StudentRequest.Type
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.StudentRequest.TypeView

  def index(conn, %{}) do
    types = Repo.all(Type)
    render(conn, TypeView, "index.json", types: types)
  end
end