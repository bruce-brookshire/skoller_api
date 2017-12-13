defmodule ClassnavapiWeb.Api.V1.CSVController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def professors(conn, %{"file" => file} = params) do
    t = file.path 
        |> File.stream!()
        |> CSV.decode()
        |> Enum.take_every(1)
  end
end