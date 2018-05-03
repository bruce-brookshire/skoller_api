defmodule SkollerWeb.Jobs.ClearLocks do
  
  alias Skoller.Locks

  @open_lock_mins 60

  def run() do
    Locks.get_incomplete_locks(@open_lock_mins)
    |> Locks.unlock_locks()
  end
end