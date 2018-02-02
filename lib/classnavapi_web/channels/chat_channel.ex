defmodule ClassnavapiWeb.ChatChannel do
  use Phoenix.Channel

  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Chat.Post
  alias Classnavapi.Chat.Comment
  alias Classnavapi.Chat.Reply

  def join("chat:" <> class_id, _params, socket) do
    case Repo.get_by(StudentClass, student_id: socket.assigns.user.student.id, class_id: class_id, is_dropped: false) do
      nil -> {:error, %{reason: "unauthorized"}}
      _ -> {:ok, socket}
    end
  end

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
end