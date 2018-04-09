defmodule Skoller.HighSchools do
  
    alias Skoller.Repo
    alias Skoller.Schools.Class
  
    def create_class_changeset(params) do
      Class.hs_changeset(%Class{}, params)
    end
  
    def update_class(%Class{} = class, params) do
      Class.hs_changeset(class, params)
      |> Repo.update()
    end
  end