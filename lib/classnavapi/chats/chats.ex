defmodule Classnavapi.Chats do

  alias Classnavapi.Repo
  alias Classnavapi.Chat.Post
  alias Classnavapi.Chat.Post.Star, as: PStar
  alias Classnavapi.Chat.Comment
  alias Classnavapi.Chat.Comment.Star, as: CStar
  alias Classnavapi.Chat.Reply
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Class
  alias Classnavapi.Schools.ClassPeriod
  alias Classnavapi.Schools.School

  import Ecto.Query

  def get_chat_notifications(student_id) do
    posts = from(p in Post)
    |> join(:inner, [p], sc in StudentClass, sc.class_id == p.class_id)
    |> join(:inner, [p, sc], s in PStar, s.chat_post_id == p.id and s.student_id == sc.student_id)
    |> join(:inner, [p, sc, s], c in subquery(distinct_post_id(student_id)), c.chat_post_id == p.id)
    |> join(:inner, [p, sc, s, c], cl in Class, cl.id == p.class_id)
    |> join(:inner, [p, sc, s, c, cl], cp in ClassPeriod, cp.id == cl.class_period_id)
    |> join(:inner, [p, sc, s, c, cl, cp], sch in School, cp.school_id == sch.id)
    |> where([p, sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([p, sc, s, c, cl], cl.is_chat_enabled == true)
    |> where([p, sc, s, c, cl, cp, sch], sch.is_chat_enabled == true)
    |> select([p, sc, s, c], %{chat_post: p, color: sc.color, star: s})
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :response, most_recent_response(&1.chat_post.id, student_id)))
  
    comments = from(c in Comment)
    |> join(:inner, [c], p in Post, c.chat_post_id == p.id)
    |> join(:inner, [c, p], sc in StudentClass, sc.class_id == p.class_id)
    |> join(:inner, [c, p, sc], s in CStar, s.chat_comment_id == c.id and s.student_id == sc.student_id)
    |> join(:inner, [c, p, sc, s], r in subquery(most_recent_reply(student_id)), r.chat_comment_id == c.id)
    |> join(:left, [c, p, sc, s, r], ps in PStar, ps.chat_post_id == p.id and ps.student_id == ^student_id)
    |> join(:inner, [c, p, sc, s, r, ps], cl in Class, cl.id == p.class_id)
    |> join(:inner, [c, p, sc, s, r, ps, cl], cp in ClassPeriod, cp.id == cl.class_period_id)
    |> join(:inner, [c, p, sc, s, r, ps, cl, cp], sch in School, cp.school_id == sch.id)
    |> where([c, p, sc], sc.student_id == ^student_id and sc.is_dropped == false)
    |> where([c, p, sc, s, r, ps], is_nil(ps.id)) # Don't get comment stars if post commented.
    |> where([c, p, sc, s, r, ps, cl], cl.is_chat_enabled == true)
    |> where([c, p, sc, s, r, ps, cl, cp, sch], sch.is_chat_enabled == true)
    |> order_by([c, p, sc, s, r], desc: r.updated_at)
    |> distinct([c], c.chat_post_id)
    |> select([c, p, sc, s, r], %{chat_comment: c, color: sc.color, star: s, parent_post: p, response: %{response: r.reply, is_reply: true, id: r.id, updated_at: r.updated_at}})
    |> Repo.all()
  
    posts ++ comments
  end

  defp distinct_post_id(student_id) do
    from(c in Comment)
    |> join(:left, [c], r in Reply, r.chat_comment_id == c.id)
    |> where([c], c.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> or_where([c, r], r.student_id != ^student_id)
    |> distinct([c], c.chat_post_id)
  end

  defp most_recent_response(post_id, student_id) do
    comment = from(c in Comment)
    |> where([c], c.chat_post_id == ^post_id and c.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> order_by([c], desc: c.updated_at)
    |> limit(1)
    |> select([c], %{chat_post_id: c.chat_post_id, response: c.comment, is_reply: false, updated_at: c.updated_at, id: c.id})
    |> Repo.one()

    reply = from(r in Reply)
    |> join(:inner, [r], c in Comment, c.id == r.chat_comment_id)
    |> where([r, c], c.chat_post_id == ^post_id and r.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> order_by([r], desc: r.updated_at)
    |> limit(1)
    |> select([r, c], %{chat_post_id: c.chat_post_id, response: r.reply, is_reply: true, updated_at: r.updated_at, id: r.id})
    |> Repo.one()

    compare_dates(comment, reply)
  end

  defp compare_dates(nil, reply), do: reply
  defp compare_dates(comment, nil), do: comment
  defp compare_dates(comment, reply) do
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
end