defmodule Skoller.Chats.Schools do
  @moduledoc """
  A context module for chat in schools
  """

  alias Skoller.Classes.Class
  alias Skoller.Repo
  alias Skoller.ChatPosts.Post
  alias Skoller.Classes.Schools

  import Ecto.Query

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
end