defmodule SkollerWeb.Api.V1.Class.Help.TypeController do
  @moduledoc false

  use SkollerWeb, :controller
  
  alias Skoller.Class.Help.Type
  alias Skoller.Repo
  alias SkollerWeb.Class.Help.TypeView

  def index(conn, %{}) do
    types = Repo.all(Type)
    render(conn, TypeView, "index.json", types: types)
  end
end