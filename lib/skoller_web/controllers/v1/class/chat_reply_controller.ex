defmodule SkollerWeb.Api.V1.Class.ChatReplyController do
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

    case ChatReplies.create_reply(params, conn.assigns[:user].student_id) do
      {:ok, reply} ->
        conn
        |> put_view(ChatReplyView)
        |> render("show.json", %{
          chat_reply: reply,
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
    reply_old = ChatReplies.get_reply_by_student_and_id!(conn.assigns[:user].student_id, id)

    case ChatReplies.update(reply_old, params) do
      {:ok, reply} ->
        conn
        |> put_view(ChatReplyView)
        |> render("show.json", %{
          chat_reply: reply,
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
