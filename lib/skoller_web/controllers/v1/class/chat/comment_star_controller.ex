defmodule SkollerWeb.Api.V1.Class.Chat.CommentStarController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Chat.Comment.Star
  alias SkollerWeb.Class.ChatCommentView

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

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
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
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
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end