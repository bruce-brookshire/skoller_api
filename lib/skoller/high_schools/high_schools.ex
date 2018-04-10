defmodule Skoller.HighSchools do
  
    alias Skoller.Repo
    alias Skoller.Schools.Class
  
    def get_changeset(old_class \\ %Class{}, params) do
      Class.hs_changeset(old_class, params)
    end
  
    def update_class(%Class{} = class, params) do
      Class.hs_changeset(class, params)
      |> Repo.update()
    end
  end