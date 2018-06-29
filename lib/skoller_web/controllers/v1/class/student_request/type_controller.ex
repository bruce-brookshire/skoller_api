defmodule SkollerWeb.Api.V1.Class.StudentRequest.TypeController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.StudentRequests.Type
  alias Skoller.Repo
  alias SkollerWeb.Class.StudentRequest.TypeView

  def index(conn, %{}) do
    types = Repo.all(Type)
    render(conn, TypeView, "index.json", types: types)
  end
end