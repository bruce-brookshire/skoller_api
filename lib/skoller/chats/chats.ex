defmodule Skoller.Chats do
  @moduledoc """
  The chat context module
  """

  alias Skoller.Repo
  alias Skoller.ChatPosts.Post
  alias Skoller.ChatPosts.Star, as: PStar
  alias Skoller.ChatComments.Comment
  alias Skoller.ChatComments.Star, as: CStar
  alias Skoller.ChatReplies.Reply
  alias Skoller.Classes.Class
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Schools.School
  alias Skoller.ChatPosts.Like
  alias Skoller.EnrolledStudents

  import Ecto.Query

  @sensitivity 0.4

  @sort_hot "100"
  #@sort_recent "200"
  @sort_top_day "300"
  @sort_top_week "400"
  @sort_top_period "500"

  @doc """
  Gets chat notifications by student.

  ## Notes
   * A chat notification is all responses made by other students to starred posts or comments.
   * A starred post will have the `response` key in the return object as the most recent comment OR reply.
  
  ## Return
  Returns a list of posts and comments with the format `[%{chat_post: Skoller.ChatPosts.Post, color: String, star: Skoller.ChatPosts.Star, response: response}]`
  for posts, and `[%{chat_comment: Skoller.ChatComments.Comment, color: String, star: Skoller.ChatComments.Star, parent_post: Skoller.ChatPosts.Post, response: response}]`
  for comments. The `response` object is `%{chat_post_id: Id, response: Skoller.ChatComments.Comment || Skoller.ChatReplies.Reply, is_reply: Boolean, updated_at: DateTime, id: Id}`
  """
  def get_chat_notifications(student_id) do
    posts = from(p in Post)
    |> join(:inner, [p], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), sc.class_id == p.class_id)
    |> join(:inner, [p, sc], s in PStar, s.chat_post_id == p.id and s.student_id == sc.student_id)
    |> join(:inner, [p, sc, s], c in subquery(distinct_post_id(student_id)), c.chat_post_id == p.id)
    |> join(:inner, [p, sc, s, c], cl in Class, cl.id == p.class_id)
    |> join(:inner, [p, sc, s, c, cl], cp in ClassPeriod, cp.id == cl.class_period_id)
    |> join(:inner, [p, sc, s, c, cl, cp], sch in School, cp.school_id == sch.id)
    |> where([p, sc, s, c, cl], cl.is_chat_enabled == true)
    |> where([p, sc, s, c, cl, cp, sch], sch.is_chat_enabled == true)
    |> select([p, sc, s], %{chat_post: p, color: sc.color, star: s})
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :response, most_recent_response(&1.chat_post.id, student_id)))
  
    comments = from(c in Comment)
    |> join(:inner, [c], p in Post, c.chat_post_id == p.id)
    |> join(:inner, [c, p], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), sc.class_id == p.class_id)
    |> join(:inner, [c, p, sc], s in CStar, s.chat_comment_id == c.id and s.student_id == sc.student_id)
    |> join(:inner, [c, p, sc, s], r in subquery(most_recent_reply(student_id)), r.chat_comment_id == c.id)
    |> join(:left, [c, p, sc, s, r], ps in PStar, ps.chat_post_id == p.id and ps.student_id == ^student_id)
    |> join(:inner, [c, p, sc, s, r, ps], cl in Class, cl.id == p.class_id)
    |> join(:inner, [c, p, sc, s, r, ps, cl], cp in ClassPeriod, cp.id == cl.class_period_id)
    |> join(:inner, [c, p, sc, s, r, ps, cl, cp], sch in School, cp.school_id == sch.id)
    |> where([c, p, sc, s, r, ps], is_nil(ps.id)) # Don't get comment stars if post commented.
    |> where([c, p, sc, s, r, ps, cl], cl.is_chat_enabled == true)
    |> where([c, p, sc, s, r, ps, cl, cp, sch], sch.is_chat_enabled == true)
    |> order_by([c, p, sc, s, r], desc: r.updated_at)
    |> distinct([c], c.chat_post_id)
    |> select([c, p, sc, s, r], %{chat_comment: c, color: sc.color, star: s, parent_post: p, response: %{response: r.reply, is_reply: true, id: r.id, updated_at: r.updated_at}})
    |> Repo.all()
  
    posts ++ comments
  end

  @doc """
  Gets the chat posts for all of a student's classes. Defaults to most recent ordering.

  ## Filters
   * "sort" => `Skoller.Chats.Algorithm`

  ## Returns
  `[%{chat_post: Skoller.ChatPosts.Post, color: String, enroll: Integer, likes: Integer}]` or `[]`
  """
  def get_student_chat(student_id, filters) do
    from(p in Post)
    |> join(:inner, [p], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), sc.class_id == p.class_id)
    |> join(:inner, [p, sc], enroll in subquery(enrollment_subquery(student_id)), enroll.class_id == sc.class_id)
    |> join(:inner, [p, sc, enroll], c in Class, c.id == p.class_id)
    |> join(:inner, [p, sc, enroll, c], cp in ClassPeriod, cp.id == c.class_period_id)
    |> join(:inner, [p, sc, enroll, c, cp], s in School, cp.school_id == s.id)
    |> join(:left, [p, sc, enroll, c, cp, s], l in subquery(like_subquery(student_id)), l.chat_post_id == p.id)
    |> where([p, sc, enroll, c], c.is_chat_enabled == true)
    |> where([p, sc, enroll, c, cp, s], s.is_chat_enabled == true)
    |> where_by_params(filters)
    |> select([p, sc, enroll, c, cp, s, l], %{chat_post: p, color: sc.color, enroll: enroll.count, likes: l.count})
    |> order_by([p, sc], desc: p.inserted_at)
    |> Repo.all()
    |> sort_by_params(filters)
  end

  @doc """
  Returns whether any item in `chat_item_enum` is liked by `student_id`.

  ## Notes
  Can be posts, comments, or likes.

  ## Returns
  `Boolean`
  """
  def is_liked([], _student_id), do: false
  def is_liked(chat_item_enum, student_id) do
    chat_item_enum |> Repo.preload(:likes)
    chat_item_enum.likes |> Enum.any?(& to_string(&1.student_id) == to_string(student_id))
  end

  defp sort_by_params(enum, %{"sort" => @sort_hot}) do
    enum
    |> Enum.sort(&hot_algorithm(&1) >= hot_algorithm(&2))
  end
  defp sort_by_params(enum, %{"sort" => sort}) when sort in [@sort_top_day, @sort_top_period, @sort_top_week] do
    enum |> Enum.sort(& &1.likes / &1.enroll >= &2.likes / &2.enroll)
  end
  defp sort_by_params(enum, _params), do: enum

  # See Jon
  defp hot_algorithm(%{enroll: enroll, likes: likes, chat_post: %{inserted_at: tsp}}) do
    ratio = likes / enroll
    tsp = tsp |> DateTime.from_naive!("Etc/UTC")
    tsp = DateTime.utc_now() |> DateTime.diff(tsp, :second)
    tsp = tsp / 86_400
    1 / (1 + (:math.exp(tsp * @sensitivity * :math.log(tsp + 1) - ratio)))
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

  # Gets the number of likes for each post in student_id's classes.
  defp like_subquery(student_id) do
    from(sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], p in Post, sc.class_id == p.class_id)
    |> join(:left, [sc, p], l in Like, l.chat_post_id == p.id)
    |> group_by([sc, p], p.id)
    |> select([sc, p, l], %{chat_post_id: p.id, count: count(l.id)})
  end

  # Gets number of students in each of student_id's classes
  defp enrollment_subquery(student_id) do
    from(sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)))
    |> join(:inner, [sc], enroll in subquery(EnrolledStudents.get_enrolled_student_classes_subquery()), sc.class_id == enroll.class_id)
    |> group_by([sc, enroll], enroll.class_id)
    |> select([sc, enroll], %{class_id: enroll.class_id, count: count(enroll.id)})
  end

  # Gets distinct post ids where a comment or reply has been made by someone other than the student.
  defp distinct_post_id(student_id) do
    from(c in Comment)
    |> join(:left, [c], r in Reply, r.chat_comment_id == c.id)
    |> where([c], c.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> or_where([c, r], r.student_id != ^student_id)
    |> distinct([c], c.chat_post_id)
  end

  # Gets the most recent comment or reply on a post made by someone other than the student.
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

  # gets the most recent reply on a comment that is starred by student_id
  defp most_recent_reply(student_id) do
    from(r in Reply)
    |> join(:inner, [r], s in CStar, s.chat_comment_id == r.chat_comment_id)
    |> where([r, s], s.student_id == ^student_id and r.student_id != ^student_id) #Stop a student from getting hit with their own updates
    |> order_by([r], desc: r.updated_at)
    |> limit(1)
  end
end