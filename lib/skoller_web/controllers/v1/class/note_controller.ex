defmodule SkollerWeb.Api.V1.Class.NoteController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Admin.ClassView
  alias Skoller.AdminClasses

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{"class_id" => class_id} = params) do
    class = AdminClasses.create_note(class_id, params)

    render(conn, ClassView, "show.json", class: class)
  end
end