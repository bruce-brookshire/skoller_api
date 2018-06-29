defmodule SkollerWeb.ChatChannel do
  @moduledoc """
  A Channel for using chat and posting messages through a websocket.
  
  ## Join a class chat
  To join a class chat, send a topic of "chat:`class_id`"

  #### Returns
   * If joined successfully, the socket is maintained.
   * If the class has chat disabled, `{reason: "Chat disabled"}` is returned.
   * If the student is not authorized, `{error: "unauthorized"}` is returned.
  
  ## To post
  To post in a class, send a topic of post, with `{body: String}`
  The post will broadcast.

  #### Returns
   * If successful, the socket is maintained.
   * Otherwise, `{error: "Failed to create post"}` is returned.
  
  ## To comment
  To comment in a class, send a topic of comment, with `{body: String, post_id: Id}`
  The comment will broadcast.

  #### Returns
   * If successful, the socket is maintained.
   * Otherwise, `{error: "Failed to add comment"}` is returned.

  ## To reply
  To reply in a class, send a topic of reply, with `{body: String, comment_id: Id}`
  The reply will broadcast.

  #### Returns
   * If successful, the socket is maintained.
   * Otherwise, `{error: "Failed to reply"}` is returned.
  """

  # This socket is not currently used anywhere.
  # Testing this is really difficult. Try to find a websocket client.
  use Phoenix.Channel

  alias Skoller.Repo
  alias Skoller.ChatPosts.Post
  alias Skoller.ChatComments.Comment
  alias Skoller.ChatReplies.Reply
  alias Skoller.Classes
  alias Skoller.Schools
  alias Skoller.Students

  @doc false
  # Joins a class after checking that the class has chat enabled and the student is enrolled.
  def join("chat:" <> class_id, _params, socket) do
    case get_class_enabled(class_id) do
      {:ok, _val} ->
        case Students.get_enrolled_class_by_ids(class_id, socket.assigns.user.student.id) do
          nil -> {:reply, %{error: "unauthorized"}}
          _ -> {:ok, socket}
        end
      {:error, _val} ->
        {:error, %{reason: "Chat disabled"}}
    end
  end

  @doc false
  # Handles incoming requests.
  # Broadcast will send an update to all users.
  def handle_in("post", %{"body" => body}, socket) do
    "chat:" <> class_id = socket.topic
    changeset = Post.changeset(%Post{}, %{class_id: class_id, student_id: socket.assigns.user.student.id, post: body})
    case Repo.insert(changeset) do
      {:ok, _post} ->
        broadcast! socket, "post", %{body: body}
        {:noreply, socket}
      {:error, _changeset} ->
        {:reply, %{error: "Failed to create post"}}
    end
  end
  def handle_in("comment", %{"body" => body, "post_id" => post_id}, socket) do
    changeset = Comment.changeset(%Comment{}, %{chat_post_id: post_id, student_id: socket.assigns.user.student.id, comment: body})
    case Repo.insert(changeset) do
      {:ok, _comment} ->
        broadcast! socket, "comment", %{body: body, post_id: post_id}
        {:noreply, socket}
      {:error, _changeset} ->
        {:reply, %{error: "Failed to add comment"}}
    end
  end
  def handle_in("reply", %{"body" => body, "comment_id" => comment_id}, socket) do
    changeset = Reply.changeset(%Reply{}, %{chat_comment_id: comment_id, student_id: socket.assigns.user.student.id, reply: body})
    case Repo.insert(changeset) do
      {:ok, _reply} ->
        broadcast! socket, "reply", %{body: body, comment_id: comment_id}
        {:noreply, socket}
      {:error, _changeset} ->
        {:reply, %{error: "Failed to reply"}}
    end
  end

  defp get_class_enabled (class_id) do
    {:ok, Map.new}
    |> get_class(class_id)
    |> get_school()
  end

  defp get_class({:ok, map}, class_id) do
    case Classes.get_class_by_id(class_id) do
      %{is_chat_enabled: true} = class -> 
        {:ok, map |> Map.put(:class, class)}
      _ -> {:error, map}
    end
  end

  defp get_school({:error, _nil} = map), do: map
  defp get_school({:ok, %{class: %{class_period_id: class_period_id}} = map}) do
    case Schools.get_school_from_period(class_period_id) do
      %{is_chat_enabled: true} = school -> 
        {:ok, map |> Map.put(:school, school)}
      _ -> 
        {:error, map}
    end
  end
end