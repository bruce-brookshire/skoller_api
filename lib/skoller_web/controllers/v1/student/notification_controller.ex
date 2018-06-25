defmodule SkollerWeb.Api.V1.Student.NotificationController do
  use SkollerWeb, :controller

  alias SkollerWeb.Student.NotificationView
  alias Skoller.Chats
  alias Skoller.Assignments.Mods
  alias Skoller.Assignments

  import SkollerWeb.Helpers.AuthPlug

  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def notifications(conn, %{"student_id" => student_id}) do
    inbox = Chats.get_chat_notifications(student_id)
            |> Enum.map(&Map.put(%{}, :inbox, &1))
    mods = Mods.get_student_mods(student_id)
            |> Enum.map(&Map.put(%{}, :mod, &1))
    assignment_posts = Assignments.get_assignment_post_notifications(student_id)
            |> Enum.map(&Map.put(%{}, :assignment_post, &1))

    notifications = inbox ++ mods ++ assignment_posts |> Enum.sort(&DateTime.compare(get_date(&1), get_date(&2)) in [:gt, :eq])

    render(conn, NotificationView, "index.json", %{notifications: notifications})
  end

  defp get_date(%{inbox: inbox}), do: inbox.response.updated_at |> DateTime.from_naive!("Etc/UTC")
  defp get_date(%{mod: mod}), do: mod.mod.inserted_at |> DateTime.from_naive!("Etc/UTC")
  defp get_date(%{assignment_post: assignment_post}), do: assignment_post.post.updated_at |> DateTime.from_naive!("Etc/UTC")
end