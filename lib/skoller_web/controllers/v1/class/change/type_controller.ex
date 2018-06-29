defmodule SkollerWeb.Api.V1.Class.Change.TypeController do
  @moduledoc false

  use SkollerWeb, :controller
  
  alias Skoller.ChangeRequests.Type
  alias Skoller.Repo
  alias SkollerWeb.Class.Change.TypeView

  def index(conn, _) do
    types = Repo.all(Type)
    render(conn, TypeView, "index.json", types: types)
  end
end