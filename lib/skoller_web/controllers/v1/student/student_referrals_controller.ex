defmodule SkollerWeb.Api.V1.Student.StudentReferralsController do
  @moduledoc false

  use SkollerWeb, :controller

  import Plug.Conn

  alias SkollerWeb.Student.ReferredStudentsView

  def referred_students(conn, params) do
    IO.inspect(params)

    conn
    |> put_view(ReferredStudentsView)
    |> render("referred_students.json", stuff: nil)

  end
end
