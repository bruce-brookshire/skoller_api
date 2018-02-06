defmodule ClassnavapiWeb.Api.V1.Class.Chat.PostLikeController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post.Like
  alias ClassnavapiWeb.Class.ChatPostView

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Like.changeset(%Like{}, params)

    case Repo.insert(changeset) do
      {:ok, like} -> 
        like = like |> Repo.preload(:chat_post)
        render(conn, ChatPostView, "show.json", %{chat_post: like.chat_post, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    like = Repo.get!(Like, id)
    case Repo.delete(like) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end