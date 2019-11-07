defmodule SkollerWeb.SessionView do
  use SkollerWeb, :view

  def render("show.json", %{session: %{session_platform: session_platform} = session}) do
    session_platform = session_platform |> Map.take([:id, :type])

    session
    |> Map.take([:id, :user_id, :updated_at, :inserted_at])
    |> Map.put(:session_platform, session_platform)
  end
end
