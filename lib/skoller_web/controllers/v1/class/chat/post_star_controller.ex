defmodule SkollerWeb.Api.V1.Class.Chat.PostStarController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Class.ChatPostView
  alias Skoller.EnrolledStudents
  alias Skoller.ChatPosts
  alias Skoller.Chats

  import SkollerWeb.Plugs.Auth
  import SkollerWeb.Plugs.ChatAuth

  @student_role 100

  plug :verify_role, %{role: @student_role}
  plug :check_chat_enabled
  plug :verify_member, :class

  def create(conn, %{"class_id" => class_id} = params) do
    case ChatPosts.star_post(params["chat_post_id"], conn.assigns[:user].student_id) do
      {:ok, chat_post} ->
        sc = EnrolledStudents.get_enrolled_class_by_ids!(class_id, conn.assigns[:user].student_id)

        conn
        |> put_view(ChatPostView)
        |> render("show.json", %{
          chat_post: %{chat_post: chat_post, color: sc.color},
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"chat_post_id" => post_id}) do
    case ChatPosts.unstar_post(post_id, conn.assigns[:user].student_id) do
      {:ok, chat_post} ->
        sc =
          EnrolledStudents.get_enrolled_class_by_ids!(
            chat_post.class_id,
            conn.assigns[:user].student_id
          )

        conn
        |> put_view(ChatPostView)
        |> render("show.json", %{
          chat_post: %{chat_post: chat_post, color: sc.color},
          current_student_id: conn.assigns[:user].student_id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(conn, %{"chat_post_id" => post_id}) do
    case Chats.read_chat(post_id, conn.assigns[:user].student_id) do
      {:ok, _} -> conn |> send_resp(204, "")
      {:error, _} -> conn |> send_resp(422, "")
    end
  end
end
