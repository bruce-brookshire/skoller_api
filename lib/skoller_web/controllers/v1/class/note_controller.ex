defmodule SkollerWeb.Api.V1.Class.NoteController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Admin.ClassView
  alias Skoller.Classes
  alias Skoller.Notes

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def create(conn, %{"class_id" => class_id} = params) do
    case Notes.create_note(params) do
      {:ok, _note} ->
        class = Classes.get_full_class_by_id!(class_id)

        conn
        |> put_view(ClassView)
        |> render("show.json", class: class)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
