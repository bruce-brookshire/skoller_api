defmodule Skoller.Universities do

  alias Skoller.Repo
  alias Skoller.Schools.Class

  def create_class_changeset(params) do
    Class.university_changeset(%Class{}, params)
  end

  def update_class(%Class{} = class, params) do
    Class.university_changeset(class, params)
    |> Repo.update()
  end
end