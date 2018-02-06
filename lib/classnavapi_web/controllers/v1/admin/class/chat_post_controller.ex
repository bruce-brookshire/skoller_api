defmodule ClassnavapiWeb.Api.V1.Admin.Class.ChatPostController do
  use ClassnavapiWeb, :controller
  
  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias ClassnavapiWeb.Class.ChatPostView

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query
  import ClassnavapiWeb.Helpers.ChatPlug

  @student_role 100
  @admin_role 200

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :check_chat_enabled
  plug :verify_member, :class

  def delete(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    case Repo.delete(post) do
      {:ok, _struct} ->
        conn
        |> send_resp(200, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    posts = from(p in Post)
    |> where([p], p.class_id == ^class_id)
    |> Repo.all()

    render(conn, ChatPostView, "index.json", chat_posts: posts)
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    render(conn, ChatPostView, "show.json", chat_post: post)
  end
end