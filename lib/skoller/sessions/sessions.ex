defmodule Skoller.Sessions do
  alias Skoller.Repo
  alias Skoller.Sessions.Session

  @web_session_platform 100
  @ios_session_platform 200
  @android_session_platform 300

  def insert(%{"platform" => "web", "student_id" => student_id}),
    do: insert(student_id, @web_session_platform)

  def insert(%{"platform" => "ios", "student_id" => student_id}),
    do: insert(student_id, @ios_session_platform)

  def insert(%{"platform" => "android", "student_id" => student_id}),
    do: insert(student_id, @android_session_platform)

  def insert(student_id, session_platform_id) when is_integer(student_id) and is_integer(session_platform_id) do
    %{student_id: student_id, session_platform_id: session_platform_id}
    |> Session.insert_changeset()
    |> Repo.insert()
    |> Repo.preload([:session_platform])
  end

  def get_by_student_id(student_id) when is_integer(student_id) do
    Session
    |> Repo.get_by(student_id: student_id)
  end

  def get_by_id(id) when is_integer(id) do
    Session
    |> Repo.get(id)
  end
end
