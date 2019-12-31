defmodule Skoller.Locks.DIY do
  @moduledoc """
  A context module for class locks as a student.
  """

  alias Skoller.Locks

  @doc """
  Locks a class.

  ## Returns
  `Skoller.Locks.lock_class/4`
  """
  def lock_class(user_id, class_id, atom, subsection) do
    Locks.lock_class(class_id, user_id, atom, subsection: subsection)
  end
end
