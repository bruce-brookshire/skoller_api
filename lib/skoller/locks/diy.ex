defmodule Skoller.Locks.DIY do
  @moduledoc """
  A context module for class locks as a student.
  """

  alias Skoller.Classes
  alias Skoller.Repo
  alias Skoller.FourDoor
  alias Skoller.Locks

  @doc """
  Locks a class. Checks four door status before locking.

  ## Returns
  `Skoller.Locks.lock_class/4` or `{:error, "DIY is not enabled"}`
  """
  def lock_class(user_id, class_id, atom, subsection) do
    class = Classes.get_class_by_id!(class_id)
            |> Repo.preload(:school)
    
    fd = FourDoor.get_four_door_by_school(class.school.id)

    case fd.is_diy_enabled do
      true -> Locks.lock_class(class_id, user_id, atom, [subsection: subsection])
      false -> {:error, "DIY is not enabled."}
    end
  end
end