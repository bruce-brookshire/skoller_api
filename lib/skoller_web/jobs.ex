defmodule SkollerWeb.Jobs do
  
  alias SkollerWeb.Jobs

  def run() do
    now = Time.utc_now()

    now
    |> Jobs.SendNotifications.run()

    Jobs.ClearLocks.run()
  end
end