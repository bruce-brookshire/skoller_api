defmodule ClassnavapiWeb.Jobs do
  
  def run() do
    Time.utc_now()
    |> send_notifications()
  end

  defp send_notifications(time) do
    
  end
end