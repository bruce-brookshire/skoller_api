defmodule Skoller.Jobs.ClearLocks do
  @moduledoc false
  
  alias Skoller.Locks

  @open_lock_mins 60

  def run() do
    Locks.clear_locks(@open_lock_mins)
  end
end