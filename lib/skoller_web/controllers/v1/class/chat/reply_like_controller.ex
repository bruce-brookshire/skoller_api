defmodule SkollerWeb.Api.V1.Class.Chat.ReplyLikeController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.ChatReplyView
  alias Skoller.ChatReplies

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do
    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    case ChatReplies.like_reply(params) do
      {:ok, chat_reply} ->
        conn
        |> put_view(ChatReplyView)
        |> render("show.json", %{
          chat_reply: chat_reply,
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_reply_id" => reply_id}) do
    case ChatReplies.unlike_reply(reply_id, conn.assigns[:user].student_id) do
      {:ok, chat_reply} ->
        conn
        |> put_view(ChatReplyView)
        |> render("show.json", %{
          chat_reply: chat_reply,
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
