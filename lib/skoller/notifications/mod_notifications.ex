defmodule Skoller.ModNotifications do
  @moduledoc """
  A context module for mod notifications.
  """

  alias Skoller.Repo
  alias Skoller.Mods.Mod
  alias Skoller.Mods.Action
  alias Skoller.Notifications
  alias Skoller.Devices
  alias Skoller.ModActions
  alias Skoller.Dates
  alias Skoller.Students.Student
  alias Skoller.Services.Notification
  alias Skoller.Mods

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

  @pending_update_category "Update.Pending"
  @auto_update_category "Update.Auto"

  @a_classmate_has "A classmate has "
  @added "added "
  @removed "removed "
  @updated "updated"
  @due "due "
  @due_date "due date"
  @you_have "You have "
  @updates_pending " updates pending"
  @no_weight "no weight"

  @in_s " in "
  @of_s " of "
  @the_s " the "
  @to_s " to "
  @and_s " and "
  @c_and_s ", and "
  @notification_end "."

  @auto_delete "Autoupdate: assignment has been removed"
  @auto_add "Autoupdate: assignment has been added"
  @auto_update " has been autoupdated"

  def send_mod_update_notifications({:ok, %Action{} = action}) do
    user = Notifications.get_user_from_student_class(action.student_class_id)
    devices = user |>  get_devices_from_user()
    case devices do
      [] -> :ok
      _ -> action |> build_notifications(user, devices)
    end
  end

  def send_mod_update_notifications({:ok, %{actions: _} = mod}) do
    send_mod_update_notifications(mod)
  end

  def send_mod_update_notifications(mod) when is_list(mod) do
    mod |> Enum.each(&send_mod_update_notifications(&1))
  end

  def send_mod_update_notifications(%{actions: nil}), do: nil
  def send_mod_update_notifications({:ok, _}), do: nil
  def send_mod_update_notifications(mod) do
    mod.actions |> Enum.each(&send_mod_update_notifications(&1))
  end

  def send_auto_update_notification(actions) do
    actions |> Enum.each(&build_auto_update_notification(&1))
  end

  defp build_auto_update_notification({:ok, action}) do
    mod = ModActions.get_mod_from_action(action)
          |> Repo.preload(:assignment)
    class = Mods.get_class_from_mod_id(mod.id)
    case class.is_editable do
      true -> 
        title = case mod.assignment_mod_type_id do
          @new_assignment_mod -> @auto_add
          @delete_assignment_mod -> @auto_delete
          _ -> mod.assignment.name <> @auto_update
        end
        body = case mod.assignment_mod_type_id do
          @new_assignment_mod -> mod_add_notification_text(mod, class)
          @delete_assignment_mod -> mod_delete_notification_text(mod, class)
          _ -> text = mod_change_notification_text(mod, class)
          len = text |> String.length
          msg = text |> String.slice(0..0) |> String.upcase()
          msg <> (text |> String.slice(1..len))
        end
        Notifications.get_users_from_student_class(action.student_class_id)
        |> Enum.reduce([], &Devices.get_devices_by_user_id(&1.id) ++ &2)
        |> Enum.each(&Notification.create_notification(&1.udid, &1.type, %{title: title, body: body}, @auto_update_category))
      false -> 
        :ok
    end
  end
  defp build_auto_update_notification(_), do: nil

  defp build_notifications(%Action{} = action, %{student: student}, devices) do
    count = ModActions.get_pending_mod_count_for_student(student.id)
    msg = case count do
      1 -> action |> one_pending_mod_notification()
      num -> student |> multiple_pending_mod_notification(num)
    end
    devices |> Enum.each(&Notification.create_notification(&1.udid, &1.type, msg, @pending_update_category))
  end

  defp one_pending_mod_notification(action) do
    mod = ModActions.get_mod_from_action(action) |> Repo.preload(:assignment)
    class = Mods.get_class_from_mod_id(mod.id)
    cond do
      mod.assignment_mod_type_id == @new_assignment_mod -> @a_classmate_has <> @added <> mod_add_notification_text(mod, class)
      mod.assignment_mod_type_id == @delete_assignment_mod -> @a_classmate_has <> @removed <> mod_delete_notification_text(mod, class)
      is_nil(mod.data["due"]) -> @a_classmate_has <> @removed <> @the_s <> @due_date <> @of_s <> class_and_assign_name(mod, class)
      true -> @a_classmate_has <> @updated <> @the_s <> mod_change_notification_text(mod, class)
    end
  end

  defp multiple_pending_mod_notification(student, num) do
    @you_have <> to_string(num) <> @updates_pending <> @in_s <> class_list(student) <> @notification_end
  end

  defp mod_add_notification_text(mod, class) do
    case mod.assignment.due do
      nil ->
        mod.assignment.name <> @in_s <> class.name <> @notification_end
      due ->
        mod.assignment.name <> @in_s <> class.name <> ", " <> @due <> Dates.format_date(due) <> @notification_end
    end
  end

  defp mod_delete_notification_text(mod, class) do
    mod.assignment.name <> @in_s <> class.name <> @notification_end
  end

  defp mod_change_notification_text(%{data: %{due: nil}} = mod, class) do
    @removed <> " " <> mod_type(mod) <> @of_s <> class_and_assign_name(mod, class)
  end
  defp mod_change_notification_text(mod, class) do
    mod_type(mod) <> @of_s <> class_and_assign_name(mod, class) <> @to_s <> mod_change(mod) <> @notification_end
  end

  defp class_and_assign_name(mod, class) do
    class.name <> " " <> mod.assignment.name
  end

  defp mod_change(%Mod{assignment_mod_type_id: type, data: data}) do
    case type do
      @name_assignment_mod -> data["name"]
      @weight_assignment_mod -> get_weight_from_id(data["weight_id"])
      @due_assignment_mod -> format_date_from_iso(data["due"])
    end
  end

  defp mod_type(%Mod{assignment_mod_type_id: type}) do
    case type do
      @name_assignment_mod -> "name"
      @weight_assignment_mod -> "weight"
      @due_assignment_mod -> "due date"
    end
  end
  
  defp get_weight_from_id(nil), do: @no_weight
  
  defp get_weight_from_id(id) do
    weight = Repo.get!(Weight, id)
    weight.name
  end

  defp format_date_from_iso(date) do
    {:ok, date, _offset} = date |> DateTime.from_iso8601()
    
    date |> Dates.format_date()
  end

  defp class_list(%Student{} = student) do
    Mods.get_classes_with_pending_mod_by_student_id(student.id)
    |> format_list()
  end

  defp format_list(list) do
    head = list |> List.first()
    tail = list |> List.last()
    case list |> Enum.count() do
      1 -> head.name
      2 -> head.name <> @and_s <> tail.name
      _ -> str = list |> List.delete_at(-1)
                      |> List.delete_at(0)
                      |> List.foldl(@c_and_s <> tail.name, & ", " <> &1.name <> &2)
        head.name <> str
    end
  end

  defp get_devices_from_user(nil), do: []
  defp get_devices_from_user(%{user: user}) do
    user.id |> Devices.get_devices_by_user_id()
  end
end