defmodule ClassnavapiWeb.ChatChannel do
  use Phoenix.Channel

  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Chat.Post
  alias Classnavapi.Chat.Comment
  alias Classnavapi.Chat.Reply
  alias Classnavapi.Class
  alias Classnavapi.Schools

  def join("chat:" <> class_id, _params, socket) do
    case get_class_enabled(class_id) do
      {:ok, _val} ->
        case Repo.get_by(StudentClass, student_id: socket.assigns.user.student.id, class_id: class_id, is_dropped: false) do
          nil -> {:reply, %{error: "unauthorized"}}
          _ -> {:ok, socket}
        end
      {:error, _val} ->
        {:error, %{reason: "Chat disabled"}}
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

  defp get_class_enabled (class_id) do
    {:ok, Map.new}
    |> get_class(class_id)
    |> get_school()
  end

  defp get_class({:ok, map}, class_id) do
    case Repo.get(Class, class_id) do
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