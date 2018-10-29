defmodule Skoller.Analytics.Chats do
  @moduledoc """
  A context module for running analytics on chat.
  """

  alias Skoller.ChatPosts.Post
  alias Skoller.Repo
  alias Skoller.Classes.Schools
  alias Skoller.Classes.Class
  alias Skoller.ChatComments.Comment
  alias Skoller.ChatReplies.Reply

  import Ecto.Query

  @doc """
  Gets a count of classes that have chat activity

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_classes_with_chat_count(dates, params) do
    from(cp in subquery(get_unique_chat_class(dates)))
    |> join(:inner, [cp], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == cp.class_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a count of chat posts.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school
  
  """
  def get_chat_post_count(dates, params) do
    from(cp in Post)
    |> join(:inner, [cp], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == cp.class_id)
    |> where([cp], fragment("?::date", cp.inserted_at) >= ^dates.date_start and fragment("?::date", cp.inserted_at) <= ^dates.date_end)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets the class with the highest amount of chat posts between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `%{class: Skoller.Classes.Class, count: Integer}` or `nil`
  """
  def get_max_chat_activity(%{date_start: _date_start, date_end: _date_end} = dates, params) do
    from(c in Class)
    |> join(:inner, [c], cp in subquery(get_max_chat_activity_subquery(dates, params)), cp.class_id == c.id)
    |> select([c, cp], %{class: c, count: cp.count})
    |> Repo.one()
  end

  @doc """
  Gets the class with the highest amount of chat posts between the dates.

  ## Dates
   * `Map`, `%{date_start: DateTime, date_end: DateTime}`

  ## Params
   * `Map`, `%{"school_id" => Id}` filters by school

  ## Returns
  `%{class: Skoller.Classes.Class, count: Integer}` or `nil`
  """
  def get_chat_participating_students_count(dates, params) do
    post_students = from(p in Post)
    |> join(:inner, [p], c in subquery(Schools.get_school_from_class_subquery(params)), p.class_id == c.class_id)
    |> where([p], fragment("?::date", p.inserted_at) >= ^dates.date_start and fragment("?::date", p.inserted_at) <= ^dates.date_end)
    |> distinct([p], p.student_id)
    |> select([p], p.student_id)
    |> Repo.all()

    comment_students = from(c in Comment)
    |> join(:inner, [c], p in Post, p.id == c.chat_post_id)
    |> join(:inner, [c, p], cl in subquery(Schools.get_school_from_class_subquery(params)), p.class_id == cl.class_id)
    |> where([c], fragment("?::date", c.inserted_at) >= ^dates.date_start and fragment("?::date", c.inserted_at) <= ^dates.date_end)
    |> where([c], c.student_id not in ^post_students)
    |> distinct([c], c.student_id)
    |> select([c], c.student_id)
    |> Repo.all()

    students = post_students ++ comment_students

    reply_students = from(r in Reply)
    |> join(:inner, [r], c in Comment, r.chat_comment_id == c.id)
    |> join(:inner, [r, c], p in Post, p.id == c.chat_post_id)
    |> join(:inner, [r, c, p], cl in subquery(Schools.get_school_from_class_subquery(params)), p.class_id == cl.class_id)
    |> where([r], fragment("?::date", r.inserted_at) >= ^dates.date_start and fragment("?::date", r.inserted_at) <= ^dates.date_end)
    |> where([r], r.student_id not in ^students)
    |> distinct([r], r.student_id)
    |> select([r], r.student_id)
    |> Repo.all()

    students ++ reply_students
    |> Enum.count()
  end

  # Gets the top class_id and the count of posts in the class.
  defp get_max_chat_activity_subquery(dates, params) do
    from(cp in subquery(get_chat_activity_subquery(dates, params)))
    |> group_by([cp], cp.class_id)
    |> select([cp], %{class_id: cp.class_id, count: max(cp.count)})
    |> limit(1)
  end

  # This gets a list of classes and post count, with an optional school parameter.
  defp get_chat_activity_subquery(dates, params) do
    from(cp in Post)
    |> join(:inner, [cp], c in subquery(Schools.get_school_from_class_subquery(params)), c.class_id == cp.class_id)
    |> where([cp], fragment("?::date", cp.inserted_at) >= ^dates.date_start and fragment("?::date", cp.inserted_at) <= ^dates.date_end)
    |> group_by([cp], cp.class_id)
    |> select([cp], %{class_id: cp.class_id, count: count(cp.id)})
  end

  defp get_unique_chat_class(dates) do
    from(p in Post)
    |> where([p], fragment("?::date", p.inserted_at) >= ^dates.date_start and fragment("?::date", p.inserted_at) <= ^dates.date_end)
    |> distinct([p], p.class_id)
  end
end