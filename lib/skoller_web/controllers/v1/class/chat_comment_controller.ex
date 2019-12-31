defmodule SkollerWeb.Api.V1.Class.ChatCommentController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.ChatCommentView
  alias Skoller.ChatComments

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    case ChatComments.create_comment(params, conn.assigns[:user].student_id) do
      {:ok, comment} ->
        conn
        |> put_view(ChatCommentView)
        |> render("show.json", %{
          chat_comment: comment,
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    comment_old = ChatComments.get_comment_by_student_and_id!(conn.assigns[:user].student_id, id)

    case ChatComments.update(comment_old, params) do
      {:ok, comment} ->
        conn
        |> put_view(ChatCommentView)
        |> render("show.json", %{
          chat_comment: comment,
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
