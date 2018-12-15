defmodule SkollerWeb.Api.V1.Admin.Class.ScriptDocController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.DocView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.ClassDocs

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(%{assigns: %{user: user}} = conn, %{"file" => file} = params) do
    case ClassDocs.insert_multiple_syllabi_from_hash(params["class_hash"], params["period_id"], file, user.id) do
      {:ok, %{doc: doc}} ->
        render(conn, DocView, "index.json", docs: doc)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end