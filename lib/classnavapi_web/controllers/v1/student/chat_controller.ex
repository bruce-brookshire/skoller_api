defmodule ClassnavapiWeb.Api.V1.Student.ChatController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias Classnavapi.Chat.Post.Like
  alias Classnavapi.Chat.Post.Star, as: PStar
  alias Classnavapi.Chat.Comment
  alias Classnavapi.Chat.Comment.Star, as: CStar
  alias Classnavapi.Chat.Reply
  alias Classnavapi.Class.StudentClass
  alias ClassnavapiWeb.Class.ChatPostView
  alias ClassnavapiWeb.Student.InboxView

  import ClassnavapiWeb.Helpers.AuthPlug
  import Ecto.Query

  @student_role 100

  @sort_hot "100"
  @sort_recent "200"
  @sort_top_day "300"
  @sort_top_week "400"
  @sort_top_period "500"

  @sensitivity 0.4
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def chat(conn, %{"student_id" => student_id} = params) do
    posts = from(p in Post)
    |> join(:inner, [p], sc in StudentClass, sc.class_id == p.class_id)
    |> join(:inner, [p, sc], enroll in subquery(enrollment_subquery(student_id)), enroll.class_id == sc.class_id)
    |> join(:left, [p, sc, enroll], l in subquery(like_subquery(student_id)), l.chat_post_id == p.id)
    |> where([p, sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where_by_params(params)
    |> select([p, sc, enroll, l], %{chat_post: p, color: sc.color, enroll: enroll.count, likes: l.count})
    |> order_by([p, sc], desc: p.inserted_at)
    |> Repo.all()
    |> sort_by_params(params)

    render(conn, ChatPostView, "index.json", %{chat_posts: posts, current_student_id: student_id})
  end

  def inbox(conn, %{"student_id" => student_id}) do
    posts = from(p in Post)
    |> join(:inner, [p], sc in StudentClass, sc.class_id == p.class_id)
    |> join(:inner, [p, sc], s in PStar, s.chat_post_id == p.id and s.student_id == sc.student_id)
    |> join(:inner, [p, sc, s], c in subquery(distinct_post_id(student_id)), c.chat_post_id == p.id)
    |> where([p, sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> select([p, sc, s, c], %{chat_post: p, color: sc.color, star: s})
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :response, most_recent_response(&1.chat_post.id, student_id)))

    comments = from(c in Comment)
    |> join(:inner, [c], p in Post, c.chat_post_id == p.id)
    |> join(:inner, [c, p], sc in StudentClass, sc.class_id == p.class_id)
    |> join(:inner, [c, p, sc], s in CStar, s.chat_comment_id == c.id and s.student_id == sc.student_id)
    |> join(:inner, [c, p, sc, s], r in subquery(most_recent_reply(student_id)), r.chat_comment_id == c.id)
    |> join(:left, [c, p, sc, s, r], ps in PStar, ps.chat_post_id == p.id and ps.student_id == ^student_id)
    |> where([c, p, sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([c, p, sc, s, r, ps], is_nil(ps.id)) # Don't get comment stars if post commented.
    |> select([c, p, sc, s, r], %{chat_comment: c, color: sc.color, star: s, parent_post: p, response: %{response: r.reply, is_reply: true}})
    |> Repo.all()

    inbox = posts ++ comments

    render(conn, InboxView, "index.json", %{inbox: inbox, current_student_id: student_id})
  end

  defp distinct_post_id(student_id) do
    from(c in Comment)
    |> where([c], c.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> distinct([c], c.chat_post_id)
  end

  defp most_recent_response(post_id, student_id) do
    comment = from(c in Comment)
    |> where([c], c.chat_post_id == ^post_id and c.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> order_by([c], desc: c.updated_at)
    |> limit(1)
    |> select([c], %{chat_post_id: c.chat_post_id, response: c.comment, is_reply: false, updated_at: c.updated_at})
    |> Repo.one()

    reply = from(r in Reply)
    |> join(:inner, [r], c in Comment, c.id == r.chat_comment_id)
    |> where([r, c], c.chat_post_id == ^post_id and r.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> order_by([r], desc: r.updated_at)
    |> limit(1)
    |> select([r, c], %{chat_post_id: c.chat_post_id, response: r.reply, is_reply: true, updated_at: r.updated_at})
    |> Repo.one()

    compate_dates(comment, reply)
  end

  defp compate_dates(comment, nil), do: comment
  defp compate_dates(comment, reply) do
    case DateTime.compare(DateTime.from_naive!(comment.updated_at, "Etc/UTC"), DateTime.from_naive!(reply.updated_at, "Etc/UTC")) do
      :gt -> comment
      _ -> reply
    end
  end

  defp most_recent_reply(student_id) do
    from(r in Reply)
    |> join(:inner, [r], s in CStar, s.chat_comment_id == r.chat_comment_id)
    |> where([r, s], s.student_id == ^student_id and r.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> order_by([r], desc: r.updated_at)
    |> limit(1)
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
    from(sc in StudentClass)
    |> join(:inner, [sc], p in Post, sc.class_id == p.class_id)
    |> join(:left, [sc, p], l in Like, l.chat_post_id == p.id)
    |> where([sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> group_by([sc, p, l], p.id)
    |> select([sc, p, l], %{chat_post_id: p.id, count: count(l.id)})
  end

  defp enrollment_subquery(student_id) do
    from(sc in StudentClass)
    |> join(:inner, [sc], enroll in StudentClass, sc.class_id == enroll.class_id)
    |> where([sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([sc, enroll], enroll.is_dropped == false)
    |> group_by([sc, enroll], enroll.class_id)
    |> select([sc, enroll], %{class_id: enroll.class_id, count: count(enroll.id)})
  end
end