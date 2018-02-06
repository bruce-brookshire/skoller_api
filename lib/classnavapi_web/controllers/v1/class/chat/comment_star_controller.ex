defmodule ClassnavapiWeb.Api.V1.Class.Chat.CommentStarController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Comment.Star
  alias ClassnavapiWeb.Class.ChatCommentView

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Star.changeset(%Star{}, params)

    case Repo.insert(changeset) do
      {:ok, star} -> 
        star = star |> Repo.preload(:chat_comment)
        render(conn, ChatCommentView, "show.json", %{chat_comment: star.chat_comment, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_comment_id" => comment_id}) do
    star = Repo.get_by!(Star, chat_comment_id: comment_id, student_id: conn.assigns[:user].student_id)
    case Repo.delete(star) do
      {:ok, _struct} ->
        star = star |> Repo.preload(:chat_comment)
        render(conn, ChatCommentView, "show.json", %{chat_comment: star.chat_comment, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end