defmodule Skoller.Sessions do
  alias Skoller.Repo
  alias Skoller.Sessions.Session

  @web_session_platform 100
  @ios_session_platform 200
  @android_session_platform 300

  def insert(%{"platform" => "web", "user_id" => user_id}),
    do: insert(user_id, @web_session_platform)

  def insert(%{"platform" => "ios", "user_id" => user_id}),
    do: insert(user_id, @ios_session_platform)

  def insert(%{"platform" => "android", "user_id" => user_id}),
    do: insert(user_id, @android_session_platform)

  def insert(user_id, session_platform_id)
      when is_integer(user_id) and is_integer(session_platform_id) do
    %{user_id: user_id, session_platform_id: session_platform_id}
    |> Session.insert_changeset()
    |> Repo.insert()
  end

  def get_by_user_id(user_id) when is_integer(user_id) do
    Session
    |> Repo.get_by(user_id: user_id)
  end

  def get_by_id(id) when is_integer(id) do
    Session
    |> Repo.get(id)
  end
end
