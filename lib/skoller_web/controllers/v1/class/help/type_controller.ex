defmodule SkollerWeb.Api.V1.Class.Help.TypeController do
  @moduledoc false

  use SkollerWeb, :controller
  
  alias Skoller.HelpRequests
  alias SkollerWeb.Class.Help.TypeView

  def index(conn, %{}) do
    types = HelpRequests.get_help_request_types()
    render(conn, TypeView, "index.json", types: types)
  end
end