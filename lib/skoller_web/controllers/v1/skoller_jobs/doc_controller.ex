defmodule SkollerWeb.Api.V1.SkollerJobs.DocController do
  use SkollerWeb, :controller

  alias Ecto.UUID
  alias Skoller.FileUploaders.JobDocs
  alias SkollerWeb.SkollerJobs.JobView
  alias Skoller.SkollerJobs.JobProfiles

  import SkollerWeb.Plugs.{Auth, JobsAuth}

  @student_role 100
  @accepted_types ["resume", "transcript"]

  # Require access to be by a student
  plug :verify_role, %{role: @student_role}
  # Only require ownership when profile is not being created
  plug :verify_owner, :jobs_profile

  def upload(conn, %{"file" => file, "type" => type}) when type in @accepted_types do
    scope = %{file_name: UUID.generate(), dir: type}
    profile = conn.assigns[:profile]

    case process_doc(scope, file, profile) do
      {:ok, profile} ->
        conn
        |> put_view(JobView)
        |> render("show.json", profile: profile)

      _ ->
        send_resp(conn, 422, "Unable to save file")
    end
  end

  def upload(conn, %{"type" => type}) when type in @accepted_types,
    do: send_resp(conn, 422, "No file in body")

  def upload(conn, _params), do: send_resp(conn, 422, "Unsupported document type")

  defp process_doc(scope, file, profile) do
    updates =
      upload_document(file, scope)
      |> set_document_path(scope)

    JobProfiles.update(profile, updates)
  end

  defp upload_document(file_path, scope), do: JobDocs.store({file_path, scope})

  defp set_document_path({:ok, inserted}, %{:dir => type} = scope) do
    atom = String.to_atom("#{type}_url")
    path = JobDocs.url({inserted, scope})

    %{atom => path}
  end
end
