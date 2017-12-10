defmodule ClassnavapiWeb.Helpers.NotificationHelper do
  
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Notification
  alias Classnavapi.Assignment.Mod.Action
  alias Classnavapi.Student
  alias Classnavapi.Class.StudentClass
  alias Classnavapi.Assignment.Mod
  alias Classnavapi.User
  alias Classnavapi.User.Device
  alias Classnavapi.Class
  alias Classnavapi.Class.Assignment
  alias Classnavapi.Class.Weight

  import Ecto.Query

  @moduledoc """
  
  Contains helper functions for sending notifications.

  """

  @name_assignment_mod 100
  @weight_assignment_mod 200
  @due_assignment_mod 300
  @new_assignment_mod 400
  @delete_assignment_mod 500

  @one_mod_pending_update "A classmate has updated the "
  @of " of "
  @to " to "

  def send_mod_update_notifications({:ok, %Action{} = action}) do
    user = get_user_from_student_class(action.student_class_id)
    count = get_pending_mods_for_student(user.student.id)
    case count do
      1 -> user |> one_pending_mod_notification(action)
    end
  end

  def send_mod_update_notifications({:ok, %{actions: _} = mod}) do
    send_mod_update_notifications(mod)
  end

  def send_mod_update_notifications(mod) when is_list(mod) do
    mod |> Enum.each(&send_mod_update_notifications(&1))
  end

  def send_mod_update_notifications(mod) do
    mod.actions |> Enum.each(&send_mod_update_notifications(&1))
  end

  def get_user_devices(%User{} = user) do
    from(user in User)
    |> join(:inner, [user], dev in Device, user.id == dev.user_id)
    |> where([usr], usr.id == ^user.id)
    |> Repo.all
  end

  defp one_pending_mod_notification(user, action) do
    mod = get_mod_from_action(action) |> Repo.preload(:assignment)
    class = mod |> get_class_from_mod()
    t = @one_mod_pending_update <> mod_type(mod) <> @of <> class.name <> " " 
        <> mod.assignment.name <> @to <> mod_change(mod)
    require IEx
    IEx.pry
  end

  defp mod_type(%Mod{assignment_mod_type_id: type}) do
    case type do
      @name_assignment_mod -> "name"
      @weight_assignment_mod -> "weight"
      @due_assignment_mod -> "due date"
      @new_assignment_mod -> ""
      @delete_assignment_mod -> ""
    end
  end

  defp mod_change(%Mod{assignment_mod_type_id: type, data: data}) do
    case type do
      @name_assignment_mod -> data["name"]
      @weight_assignment_mod -> get_weight_from_id(data["weight_id"])
      @due_assignment_mod -> data["due"]
      @new_assignment_mod -> ""
      @delete_assignment_mod -> ""
    end
  end

  defp get_pending_mods_for_student(student_id) do
    from(act in Action)
    |> join(:inner, [act], sc in StudentClass, sc.id == act.student_class_id)
    |> join(:inner, [act, sc], stu in Student, stu.id == sc.student_id)
    |> where([act], is_nil(act.is_accepted))
    |> where([act, sc, stu], stu.is_notifications == true and stu.is_mod_notifications == true)
    |> where([act, sc, stu], stu.id == ^student_id)
    |> select([act, sc, stu], count(act.id))
    |> Repo.all
    |> List.first
  end

  defp get_user_from_student_class(student_class_id) do
    from(sc in StudentClass)
    |> join(:inner, [sc], stu in Student, stu.id == sc.student_id)
    |> join(:inner, [sc, stu], usr in User, usr.student_id == stu.id)
    |> where([sc, stu, usr], sc.id == ^student_class_id)
    |> select([sc, stu, usr], %{user: usr, student: stu})
    |> Repo.all
    |> List.first()
  end

  defp get_mod_from_action(%Action{} = action) do
    from(mod in Mod)
    |> join(:inner, [mod], act in Action, mod.id == act.assignment_modification_id)
    |> where([mod, act], act.id == ^action.id)
    |> Repo.all
    |> List.first()
  end

  defp get_class_from_mod(%Mod{} = mod) do
    from(class in Class)
    |> join(:inner, [class], assign in Assignment, class.id == assign.class_id)
    |> where([class, assign], assign.id == ^mod.assignment_id)
    |> Repo.all
    |> List.first()
  end

  defp get_weight_from_id(id) do
    weight = Repo.get!(Weight, id)
    weight.name
  end
end