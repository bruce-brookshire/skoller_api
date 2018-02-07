defmodule ClassnavapiWeb.Api.V1.Student.ChatController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias Classnavapi.Class.StudentClass
  alias ClassnavapiWeb.Class.ChatPostView

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query

  @student_role 100

  # @sort_hot 100
  @sort_recent "200"
  # @sort_top_day 300
  # @sort_top_week 400
  # @sort_top_period 500
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def chat(conn, %{"student_id" => student_id} = params) do
    posts = from(p in Post)
    |> join(:inner, [p], sc in StudentClass, sc.class_id == p.class_id)
    |> join(:inner, [p, sc], enroll in subquery(enrollment_subquery(student_id)), enroll.class_id == sc.class_id)
    |> where([p, sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> select([p, sc, enroll], %{chat_post: p, color: sc.color, enroll: enroll.count})
    |> order_by_params(params)
    |> Repo.all()

    render(conn, ChatPostView, "index.json", %{chat_posts: posts, current_student_id: student_id})
  end

  defp enrollment_subquery(student_id) do
    from(sc in StudentClass)
    |> join(:inner, [sc], enroll in StudentClass, sc.class_id == enroll.class_id)
    |> where([sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([sc, enroll], enroll.is_dropped == false)
    |> group_by([sc, enroll], enroll.class_id)
    |> select([sc, enroll], %{class_id: enroll.class_id, count: count(enroll.id)})
  end

  defp order_by_params(query, %{"sort" => @sort_recent}) do
    query
    |> order_by([p, sc], desc: p.inserted_at)
  end
  defp order_by_params(query, _params), do: query
end