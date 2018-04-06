defmodule SkollerWeb.Api.V1.Student.ChatController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.Chat.Post
  alias Skoller.Chat.Post.Like
  alias SkollerWeb.Class.ChatPostView
  alias SkollerWeb.Student.InboxView
  alias Skoller.Schools.Class
  alias Skoller.Schools.ClassPeriod
  alias Skoller.Schools.School
  alias Skoller.Chats
  alias Skoller.Students

  import SkollerWeb.Helpers.AuthPlug
  import Ecto.Query

  @student_role 100

  @sort_hot "100"
  #@sort_recent "200"
  @sort_top_day "300"
  @sort_top_week "400"
  @sort_top_period "500"

  @sensitivity 0.4
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def chat(conn, %{"student_id" => student_id} = params) do
    posts = from(p in Post)
    |> join(:inner, [p], sc in subquery(Students.get_enrolled_student_classes_subquery()), sc.class_id == p.class_id)
    |> join(:inner, [p, sc], enroll in subquery(enrollment_subquery(student_id)), enroll.class_id == sc.class_id)
    |> join(:inner, [p, sc, enroll], c in Class, c.id == p.class_id)
    |> join(:inner, [p, sc, enroll, c], cp in ClassPeriod, cp.id == c.class_period_id)
    |> join(:inner, [p, sc, enroll, c, cp], s in School, cp.school_id == s.id)
    |> join(:left, [p, sc, enroll, c, cp, s], l in subquery(like_subquery(student_id)), l.chat_post_id == p.id)
    |> where([p, sc], sc.student_id == ^student_id)
    |> where([p, sc, enroll, c], c.is_chat_enabled == true)
    |> where([p, sc, enroll, c, cp, s], s.is_chat_enabled == true)
    |> where_by_params(params)
    |> select([p, sc, enroll, c, cp, s, l], %{chat_post: p, color: sc.color, enroll: enroll.count, likes: l.count})
    |> order_by([p, sc], desc: p.inserted_at)
    |> Repo.all()
    |> sort_by_params(params)

    render(conn, ChatPostView, "index.json", %{chat_posts: posts, current_student_id: student_id})
  end

  def inbox(conn, %{"student_id" => student_id}) do
    inbox = Chats.get_chat_notifications(student_id)

    render(conn, InboxView, "index.json", %{inbox: inbox, current_student_id: student_id})
  end

  defp where_by_params(query, %{"sort" => @sort_top_day}) do
    query 
    |> where([p], p.inserted_at > ago(^1, "day"))
  end
  defp where_by_params(query, %{"sort" => @sort_top_week}) do
    query 
    |> where([p], p.inserted_at > ago(^7, "day"))
  end
  defp where_by_params(query, _params), do: query 

  defp sort_by_params(enum, %{"sort" => @sort_hot}) do
    enum
    |> Enum.sort(&hot_algorithm(&1) >= hot_algorithm(&2))
  end
  defp sort_by_params(enum, %{"sort" => sort}) when sort in [@sort_top_day, @sort_top_period, @sort_top_week] do
    enum |> Enum.sort(& &1.likes / &1.enroll >= &2.likes / &2.enroll)
  end
  defp sort_by_params(enum, _params), do: enum

  defp hot_algorithm(%{enroll: enroll, likes: likes, chat_post: %{inserted_at: tsp}}) do
    ratio = likes / enroll
    tsp = tsp |> DateTime.from_naive!("Etc/UTC")
    tsp = DateTime.utc_now() |> DateTime.diff(tsp, :second)
    tsp = tsp / 86_400
    1 / (1 + (:math.exp(tsp * @sensitivity * :math.log(tsp + 1) - ratio)))
  end

  defp like_subquery(student_id) do
    from(sc in subquery(Students.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], p in Post, sc.class_id == p.class_id)
    |> join(:left, [sc, p], l in Like, l.chat_post_id == p.id)
    |> where([sc], sc.student_id == ^student_id)
    |> group_by([sc, p, l], p.id)
    |> select([sc, p, l], %{chat_post_id: p.id, count: count(l.id)})
  end

  defp enrollment_subquery(student_id) do
    from(sc in subquery(Students.get_enrolled_student_classes_subquery()))
    |> join(:inner, [sc], enroll in subquery(Students.get_enrolled_student_classes_subquery()), sc.class_id == enroll.class_id)
    |> where([sc], sc.student_id == ^student_id)
    |> group_by([sc, enroll], enroll.class_id)
    |> select([sc, enroll], %{class_id: enroll.class_id, count: count(enroll.id)})
  end
end