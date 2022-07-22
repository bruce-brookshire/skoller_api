defmodule Skoller.Analytics.Documents do

    alias Skoller.Repo
    alias Skoller.Analytics.Documents.Document

    import Ecto.Query

    @user_fkey_id 100
    @class_fkey_id 200
    @school_fkey_id 300
    @student_fkey_id 400

    def get_current_user_csv_path() do
        csv = from(d in Document)
            |> where([d], d.analytics_document_type_id == ^@user_fkey_id)
            |> order_by([d], [desc: d.inserted_at])
            |> limit(1)
            |> Repo.one

        csv.path
    end

    def set_current_user_csv_path(path) do
        %Document{}
          |> Document.changeset(%{path: path, analytics_document_type_id: @user_fkey_id})
          |> Repo.insert
    end

    def get_current_class_csv_path() do
        csv = from(d in Document)
            |> where([d], d.analytics_document_type_id == ^@class_fkey_id)
            |> order_by([d], [desc: d.inserted_at])
            |> limit(1)
            |> Repo.one

        csv.path
    end

    def set_current_class_csv_path(path) do
        %Document{}
          |> Document.changeset(%{path: path, analytics_document_type_id: @class_fkey_id})
          |> Repo.insert
    end

    def set_current_student_referrals_csv_path(path, %{status: status}) do
        %Document{}
        |> Document.changeset(%{path: path, analytics_document_type_id: @student_fkey_id, status: status})
        |> Repo.insert
    end

    def get_current_student_referrals_csv_path() do
        csv = from(d in Document)
            |> where([d], d.analytics_document_type_id == ^@student_fkey_id)
            |> order_by([d], [desc: d.inserted_at])
            |> limit(1)
            |> Repo.one

        csv.path
    end

    def get_current_school_csv_path() do
        csv = from(d in Document)
            |> where([d], d.analytics_document_type_id == ^@school_fkey_id)
            |> order_by([d], [desc: d.inserted_at])
            |> limit(1)
            |> Repo.one

        csv.path
    end

    def set_current_school_csv_path(path) do
        %Document{}
          |> Document.changeset(%{path: path, analytics_document_type_id: @school_fkey_id})
          |> Repo.insert
    end

end
