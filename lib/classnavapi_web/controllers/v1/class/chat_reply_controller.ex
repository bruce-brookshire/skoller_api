defmodule ClassnavapiWeb.Api.V1.Class.ChatReplyController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Reply
  alias ClassnavapiWeb.Class.ChatReplyView

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Reply.changeset(%Reply{}, params)

    case Repo.insert(changeset) do
      {:ok, reply} -> 
        render(conn, ChatReplyView, "show.json", chat_reply: reply)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    reply_old = Repo.get!(Reply, id)
    
    changeset = Reply.changeset_update(reply_old, params)

    case Repo.update(changeset) do
      {:ok, reply} -> 
        render(conn, ChatReplyView, "show.json", chat_reply: reply)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end