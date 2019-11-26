defmodule SkollerWeb.Api.V1.Class.Chat.CommentLikeController do
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

    case ChatComments.like_comment(params) do
      {:ok, chat_comment} ->
        conn
        |> put_view(ChatCommentView)
        |> render("show.json", %{
          chat_comment: chat_comment,
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_comment_id" => comment_id}) do
    case ChatComments.unlike_comment(comment_id, conn.assigns[:user].student_id) do
      {:ok, chat_comment} ->
        conn
        |> put_view(ChatCommentView)
        |> render("show.json", %{
          chat_comment: chat_comment,
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
