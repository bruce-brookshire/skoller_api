defmodule ClassnavapiWeb.Api.V1.Class.ChatPostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias ClassnavapiWeb.Class.ChatPostView

  import ClassnavapiWeb.Helpers.AuthPlug
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Post.changeset(%Post{}, params)

    case Repo.insert(changeset) do
      {:ok, post} -> 
        render(conn, ChatPostView, "show.json", chat_post: post)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do

    post_old = Repo.get!(Post, id)

    changeset = Post.changeset_update(post_old, params)

    case Repo.update(changeset) do
      {:ok, post} -> 
        render(conn, ChatPostView, "show.json", chat_post: post)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end