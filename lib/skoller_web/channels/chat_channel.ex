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

  alias Skoller.EnrolledStudents
  alias Skoller.ChatPosts
  alias Skoller.ChatComments
  alias Skoller.ChatReplies
  alias Skoller.Chats.Classes

  @doc false
  # Joins a class after checking that the class has chat enabled and the student is enrolled.
  def join("chat:" <> class_id, _params, socket) do
    case Classes.check_class_chat_enabled(class_id) do
      {:ok, _val} ->
        case EnrolledStudents.get_enrolled_class_by_ids(class_id, socket.assigns.user.student.id) do
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
    case ChatPosts.create_post(%{class_id: class_id, student_id: socket.assigns.user.student.id, post: body}, socket.assigns.user.student.id) do
      {:ok, _post} ->
        broadcast! socket, "post", %{body: body}
        {:noreply, socket}
      {:error, _changeset} ->
        {:reply, %{error: "Failed to create post"}}
    end
  end
  def handle_in("comment", %{"body" => body, "post_id" => post_id}, socket) do
    case ChatComments.create_comment(%{chat_post_id: post_id, student_id: socket.assigns.user.student.id, comment: body}, socket.assigns.user.student.id) do
      {:ok, _comment} ->
        broadcast! socket, "comment", %{body: body, post_id: post_id}
        {:noreply, socket}
      {:error, _changeset} ->
        {:reply, %{error: "Failed to add comment"}}
    end
  end
  def handle_in("reply", %{"body" => body, "comment_id" => comment_id}, socket) do
    case ChatReplies.create_reply(%{chat_comment_id: comment_id, student_id: socket.assigns.user.student.id, reply: body}, socket.assigns.user.student.id) do
      {:ok, _reply} ->
        broadcast! socket, "reply", %{body: body, comment_id: comment_id}
        {:noreply, socket}
      {:error, _changeset} ->
        {:reply, %{error: "Failed to reply"}}
    end
  end
end