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

  def get_class_by_crn(crn, class_period_id) do
    Repo.get_by(Class, class_period_id: class_period_id, crn: crn)
  end
end