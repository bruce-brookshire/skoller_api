defmodule SkollerWeb.Jobs.ClearLocks do
  
  alias Skoller.Locks

  @open_lock_mins 60

  def run() do
    case Locks.get_incomplete_locks(@open_lock_mins) do
      [] -> {:ok, nil}
      locks -> 
        locks |> Locks.unlock_locks()
    end
  end
end