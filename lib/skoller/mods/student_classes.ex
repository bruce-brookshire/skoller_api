defmodule Skoller.Mods.StudentClasses do
  @moduledoc """
  A context module for student class mods.
  """

  alias Skoller.Repo
  alias Skoller.Mods
  alias Skoller.Mods.Mod
  alias Skoller.MapErrors
  alias Skoller.ModActions

  import Ecto.Query

  require Logger

  @doc """
    Adds all non added public mods to a student enrolling in a class or re-enrolling.
  """
  def add_public_mods_for_student_class(%{student_class: student_class}) do
    Logger.info("Adding public mods for student class: " <> to_string(student_class.id))
    mods = from(mod in Mod)
    |> join(:inner, [mod], class in subquery(Mods.get_class_from_mod_subquery()), mod.id == class.mod_id)
    |> where([mod], mod.is_private == false)
    |> where([mod, class], class.class_id == ^student_class.class_id)
    |> Repo.all()
    
    status = mods |> Enum.map(&ModActions.insert_mod_action(student_class, &1))
    
    status |> Enum.find({:ok, mods}, &MapErrors.check_tuple(&1))
  end
end