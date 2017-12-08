defmodule ClassnavapiWeb.Jobs do
  
  alias ClassnavapiWeb.Jobs

  def run() do
    Time.utc_now()
    |> Jobs.SendNotifications.run()
  end
end