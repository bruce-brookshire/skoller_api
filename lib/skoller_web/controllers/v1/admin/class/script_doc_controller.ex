defmodule SkollerWeb.Api.V1.Admin.Class.ScriptDocController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Class.DocView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.ClassDocs
  alias Skoller.Sammi
  alias Skoller.Classes.Periods

  import SkollerWeb.Plugs.Auth

  require Logger
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(%{assigns: %{user: user}} = conn, %{"file" => file} = params) do

    classes = Periods.get_class_from_hash(params["class_hash"], params["period_id"])
    location = file |> ClassDocs.upload_class_doc()

    classes |> Enum.each(&Task.start(Sammi, :sammi, [%{"is_syllabus" => "true", "class_id" => &1.id}, location]))

    params = params 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("is_syllabus", true)
    |> Map.put("user_id", user.id)

    case ClassDocs.multi_insert_docs(classes, params) do
      {:ok, %{doc: doc}} ->
        render(conn, DocView, "index.json", docs: doc)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end