defmodule SkollerWeb.Api.V1.Class.StudentRequest.TypeController do
  use SkollerWeb, :controller
  
  alias Skoller.Class.StudentRequest.Type
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentRequest.TypeView

  def index(conn, %{}) do
    types = Repo.all(Type)
    render(conn, TypeView, "index.json", types: types)
  end
end