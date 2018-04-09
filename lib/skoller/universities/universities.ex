defmodule Skoller.Universities do

  alias Skoller.Repo
  alias Skoller.Schools.Class

  def get_changeset(old_class \\ %Class{}, params) do
    Class.university_changeset(old_class, params)
  end

  def update_class(%Class{} = class, params) do
    Class.university_changeset(class, params)
    |> Repo.update()
  end
end