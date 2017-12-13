defmodule ClassnavapiWeb.Jobs do
  
  alias ClassnavapiWeb.Jobs

  def run() do
    now = Time.utc_now()

    now
    |> Jobs.SendNotifications.run()

    Jobs.ClearLocks.run()
  end
end