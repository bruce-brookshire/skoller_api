defmodule SkollerWeb.Api.V1.Class.Chat.PostStarController do
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Chat.Post.Star
  alias Skoller.Chat.Comment
  alias Skoller.Chat.Comment.Star, as: CommentStar
  alias SkollerWeb.Class.ChatPostView
  alias Skoller.Class.StudentClass
  alias SkollerWeb.Helpers.RepoHelper

  import SkollerWeb.Helpers.AuthPlug
  import SkollerWeb.Helpers.ChatPlug
  import Ecto.Query

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do

    params = params |> Map.put("student_id", conn.assigns[:user].student_id)

    changeset = Star.changeset(%Star{}, params)

    case Repo.insert(changeset) do
      {:ok, star} -> 
        star = star |> Repo.preload(:chat_post)
        sc = Repo.get_by!(StudentClass, student_id: conn.assigns[:user].student_id, class_id: class_id, is_dropped: false)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: star.chat_post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_post_id" => post_id}) do
    star = Repo.get_by!(Star, chat_post_id: post_id, student_id: conn.assigns[:user].student_id)
    case Repo.delete(star) do
      {:ok, _struct} ->
        star = star |> Repo.preload(:chat_post)
        sc = Repo.get_by!(StudentClass, student_id: conn.assigns[:user].student_id, class_id: star.chat_post.class_id, is_dropped: false)
        render(conn, ChatPostView, "show.json", %{chat_post: %{chat_post: star.chat_post, color: sc.color}, current_student_id: conn.assigns[:user].student_id})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"chat_post_id" => post_id}) do
    cstar = from(cs in CommentStar)
    |> join(:inner, [cs], c in Comment, cs.chat_comment_id == c.id)
    |> where([cs], cs.is_read == false and cs.student_id == ^conn.assigns[:user].student_id)
    |> where([cs, c], c.chat_post_id == ^post_id)
    |> Repo.all()

    update = case Repo.get_by(Star, chat_post_id: post_id, student_id: conn.assigns[:user].student_id) do
      nil -> cstar
      star -> cstar ++ star |> List.wrap()
    end

    status = update
    |> Enum.map(&Repo.update(Ecto.Changeset.change(&1, %{is_read: true})))
    
    case status |> Enum.find({:ok, status}, &RepoHelper.errors(&1)) do
      {:ok, _} -> conn |> send_resp(204, "")
      {:error, _} -> conn |> send_resp(422, "")
    end
  end
end