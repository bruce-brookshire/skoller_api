defmodule SkollerWeb.Api.V1.Class.ChatCommentController do
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Chat.Comment
  alias SkollerWeb.Class.ChatCommentView
  alias Skoller.Chat.Comment.Star
  alias Skoller.Chat.Post.Star, as: PostStar
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.NotificationHelper

  import SkollerWeb.Helpers.AuthPlug
  import SkollerWeb.Helpers.ChatPlug
  import Ecto.Query

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Comment.changeset(%Comment{}, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:comment, changeset)
    |> Ecto.Multi.run(:star, &insert_star(&1.comment, conn.assigns[:user].student_id))
    |> Ecto.Multi.run(:unread, &unread_posts(&1.comment, conn.assigns[:user].student_id))

    case Repo.transaction(multi) do
      {:ok, %{comment: comment}} -> 
        Task.start(NotificationHelper, :send_new_comment_notification, [comment, conn.assigns[:user].student_id])
        render(conn, ChatCommentView, "show.json", %{chat_comment: comment, current_student_id: conn.assigns[:user].student_id})
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def update(conn, %{"id" => id} = params) do
    comment_old = Repo.get_by!(Comment, id: id, student_id: conn.assigns[:user].student_id)

    changeset = Comment.changeset_update(comment_old, params)

    case Repo.update(changeset) do
      {:ok, comment} ->
        render(conn, ChatCommentView, "show.json", %{chat_comment: comment, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp unread_posts(comment, student_id) do
    items = from(s in PostStar)
    |> where([s], s.id == ^comment.chat_post_id and s.is_read == true and s.student_id != ^student_id)
    |> Repo.update_all(set: [is_read: false, updated_at: DateTime.utc_now])
    {:ok, items}
  end

  defp insert_star(comment, student_id) do
    %Star{}
    |> Star.changeset(%{chat_comment_id: comment.id, student_id: student_id})
    |> Repo.insert()
  end
end