defmodule ClassnavapiWeb.Api.V1.Student.ChatController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias Classnavapi.Class.StudentClass
  alias ClassnavapiWeb.Class.ChatPostView

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query

  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def chat(conn, %{"student_id" => student_id}) do
    posts = from(p in Post)
    |> join(:inner, [p], sc in StudentClass, sc.class_id == p.class_id)
    |> where([p, sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> select([p, sc], %{chat_post: p, color: sc.color})
    |> Repo.all()

    render(conn, ChatPostView, "index.json", %{chat_posts: posts, current_student_id: student_id})
  end

  def inbox(conn, params) do
    
  end
end