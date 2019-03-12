defmodule Skoller.Analytics.Documents do

    alias Skoller.Repo

    import Ecto.Query

    @user_fkey_id 100
    @class_fkey_id 100
    @school_fkey_id 100

    def get_current_user_csv_path() do
        
    end

    def set_new_current_user_csv_path(path) do
        %Document{} 
          |> Document.changeset(%{path: path, analytics_document_type_id: 100})
          |> Repo.insert
    end


end