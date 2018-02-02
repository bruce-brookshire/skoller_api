defmodule ClassnavapiWeb.ChatChannel do
  use Phoenix.Channel

  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Chat.Post

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
        {:error, %{reason: "Failed to create post"}}
    end
  end
end