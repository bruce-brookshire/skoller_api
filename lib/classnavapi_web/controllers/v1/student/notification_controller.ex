defmodule ClassnavapiWeb.Api.V1.Student.NotificationController do
  use ClassnavapiWeb, :controller

  alias ClassnavapiWeb.Student.NotificationView
  alias Classnavapi.Chats
  alias Classnavapi.Assignments.Mods

  import ClassnavapiWeb.Helpers.AuthPlug

  @student_role 100
  
  plug :verify_role, %{role: @student_role}
  plug :verify_member, :student

  def notifications(conn, %{"student_id" => student_id}) do
    inbox = Chats.get_chat_notifications(student_id)
            |> Enum.map(&Map.put(%{}, :inbox, &1))
            # |> Enum.map(%Map.put(&1, :current_student_id, student_id))
    mods = Mods.get_student_mods(student_id)
            |> Enum.map(&Map.put(%{}, :mod, &1))

    notifications = inbox ++ mods |> Enum.sort(&DateTime.compare(get_date(&1), get_date(&2)) in [:gt, :eq])

    render(conn, NotificationView, "index.json", %{notifications: notifications})
  end

  defp get_date(%{inbox: inbox}), do: inbox.response.updated_at |> DateTime.from_naive!("Etc/UTC")
  defp get_date(%{mod: mod}), do: mod.mod.inserted_at |> DateTime.from_naive!("Etc/UTC")
end