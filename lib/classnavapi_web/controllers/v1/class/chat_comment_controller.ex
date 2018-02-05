defmodule ClassnavapiWeb.Api.V1.Class.ChatCommentController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Comment
  alias ClassnavapiWeb.Class.ChatCommentView

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Comment.changeset(%Comment{}, params)

    case Repo.insert(changeset) do
      {:ok, comment} -> 
        render(conn, ChatCommentView, "show.json", chat_comment: comment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    comment_old = Repo.get!(Comment, id)

    changeset = Comment.changeset_update(comment_old, params)

    case Repo.update(changeset) do
      {:ok, comment} ->
        render(conn, ChatCommentView, "show.json", chat_comment: comment)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end