defmodule ClassnavapiWeb.Api.V1.CSVController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def professor(conn, %{} = params) do
    
  end
end