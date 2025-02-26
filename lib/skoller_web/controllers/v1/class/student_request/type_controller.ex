defmodule SkollerWeb.Api.V1.Class.StudentRequest.TypeController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.StudentRequests
  alias SkollerWeb.Class.StudentRequest.TypeView

  def index(conn, %{}) do
    types = StudentRequests.get_student_request_types()

    conn
    |> put_view(TypeView)
    |> render("index.json", types: types)
  end
end
