defmodule SkollerWeb.Api.V1.Class.Chat.PostLikeController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Chat.Post.Like
  alias SkollerWeb.Class.ChatPostView
  alias Skoller.Students

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Like.changeset(%Like{}, params)

    case Repo.insert(changeset) do
      {:ok, like} -> 
        like = like |> Repo.preload(:chat_post)
        sc = Students.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: like.chat_post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_post_id" => post_id}) do
    like = Repo.get_by!(Like, chat_post_id: post_id, student_id: conn.assigns[:user].student_id)
    case Repo.delete(like) do
      {:ok, _struct} ->
        like = like |> Repo.preload(:chat_post)
        sc = Students.get_enrolled_class_by_ids!(like.chat_post.class_id, conn.assigns[:user].student_id)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: like.chat_post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end