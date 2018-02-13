defmodule ClassnavapiWeb.Api.V1.NotificationController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo

  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def syllabus(conn, %{} = params) do
    
  end
end