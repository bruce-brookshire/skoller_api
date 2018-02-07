defmodule ClassnavapiWeb.Api.V1.Class.Chat.PostLikeController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post.Like
  alias ClassnavapiWeb.Class.ChatPostView
  alias Classnavapi.Class.StudentClass

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

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
        sc = Repo.get_by!(StudentClass, student_id: conn.assigns[:user].student_id, class_id: class_id, is_dropped: false)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: like.chat_post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_post_id" => post_id}) do
    like = Repo.get_by!(Like, chat_post_id: post_id, student_id: conn.assigns[:user].student_id)
    case Repo.delete(like) do
      {:ok, _struct} ->
        like = like |> Repo.preload(:chat_post)
        sc = Repo.get_by!(StudentClass, student_id: conn.assigns[:user].student_id, class_id: like.chat_post.class_id, is_dropped: false)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: like.chat_post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end