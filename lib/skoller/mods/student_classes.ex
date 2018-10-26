defmodule Skoller.Mods.StudentClasses do
  @moduledoc """
  A context module for student class mods.
  """

  alias Skoller.Repo
  alias Skoller.Mods.Classes
  alias Skoller.Mods.Mod
  alias Skoller.MapErrors
  alias Skoller.ModActions
  alias Skoller.Classes.Class
  alias Skoller.Mods.Action
  alias Skoller.EnrolledStudents

  import Ecto.Query

  require Logger

  @doc """
    Adds all non added public mods to a student enrolling in a class or re-enrolling.
  """
  def add_public_mods_for_student_class(%{student_class: student_class}) do
    Logger.info("Adding public mods for student class: " <> to_string(student_class.id))
    mods = from(mod in Mod)
    |> join(:inner, [mod], class in subquery(Classes.get_class_from_mod_subquery()), mod.id == class.mod_id)
    |> where([mod], mod.is_private == false)
    |> where([mod, class], class.class_id == ^student_class.class_id)
    |> Repo.all()
    
    status = mods |> Enum.map(&ModActions.insert_nil_mod_action(student_class.id, &1.id))
    
    status |> Enum.find({:ok, mods}, &MapErrors.check_tuple(&1))
  end

  @doc """
  Gets the enrolled classes that a student has pending mods in.

  ## Returns
  `[Skoller.Classes.Class]` or `[]`
  """
  def get_classes_with_pending_mod_by_student_id(student_id) do
    from(class in Class)
    |> join(:inner, [class], sc in subquery(EnrolledStudents.get_enrolled_classes_by_student_id_subquery(student_id)), sc.class_id == class.id)
    |> join(:inner, [class, sc], act in Action, act.student_class_id == sc.id)
    |> where([class, sc, act], is_nil(act.is_accepted))
    |> distinct([class], class.id)
    |> Repo.all()
  end
end