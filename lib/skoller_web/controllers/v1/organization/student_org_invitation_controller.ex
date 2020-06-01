defmodule SkollerWeb.Api.V1.Organization.StudentOrgInvitationController do
  alias Skoller.Organizations.StudentOrgInvitations
  alias SkollerWeb.Organization.StudentOrgInvitationView
  alias Skoller.Organizations.OrgStudents
  alias Skoller.Organizations.OrgGroups
  alias Skoller.Students
  alias SkollerWeb.CSVView
  alias Skoller.CSVUploads
  alias Skoller.Repo

  import SkollerWeb.Plugs.InsightsAuth

  use ExMvc.Controller,
    adapter: StudentOrgInvitations,
    view: StudentOrgInvitationView,
    only: [:show, :update, :create]

  plug(:verify_owner, :student_org_invites when action in [:index, :get, :update, :csv_create])

  def index(%{assigns: %{user: user}} = conn, %{"organization_id" => organization_id}) do
    case user do
      %{student: %{id: id}} ->
        invites =
          StudentOrgInvitations.get_by_params(student_id: id, organization_id: organization_id)

        put_view(conn, StudentOrgInvitationView)
        |> render("index.json", models: invites)

      %{roles: roles} ->
        case Enum.any?(roles, &(&1.id == 700 || &1.id == 200)) do
          true ->
            invites = StudentOrgInvitations.get_by_params(organization_id: organization_id)

            put_view(conn, StudentOrgInvitationView)
            |> render("index.json", models: invites)

          false ->
            conn
            |> send_resp(401, "unauthorized")
        end
    end
  end

  def respond(conn, %{"student_org_invitation_id" => invite_id, "accepts" => accepts}) do
    case StudentOrgInvitations.get_by_id(invite_id) do
      nil ->
        conn |> send_resp(401, "Not found")

      %{student_id: _, organization_id: _} = invite ->
        if accepts,
          do: Map.take(invite, [:student_id, :organization_id]) |> OrgStudents.create()

        StudentOrgInvitations.delete(invite)
        send_resp(conn, 204, "")
    end
  end

  def csv_create(conn, %{"file" => file, "organization_id" => organization_id} = params) do
    cond do
      Map.has_key?(params, "org_group_id") and not OrgGroups.exists?(id: params["org_group_id"]) ->
        send_resp(conn, 422, "Group does not exist")

      true ->
        invitations =
          file.path
          |> File.stream!()
          |> CSV.decode(headers: true)
          |> Enum.map(
            &process_student(&1, %{org_id: organization_id, group_id: params["org_group_id"]})
          )

        conn
        |> put_view(CSVView)
        |> render("index.json", csv: invitations)
    end
  end

  defp process_student({:ok, params}, opts),
    do: invite_student(params, opts)

  defp process_student(error, _org_id), do: error

  defp invite_student(%{"phone" => phone} = params, %{org_id: org_id} = opts) do
    group_ids =
      case Map.has_key?(opts, :group_id) and not is_nil(opts.group_id) do
        true -> [opts.group_id]
        false -> []
      end

    case Students.get_student_by_phone(phone) do
      %{id: student_id} ->
        %{"student_id" => student_id, "organization_id" => org_id, "group_ids" => group_ids}

      nil ->
        Map.merge(params, %{"organization_id" => org_id, "group_ids" => group_ids})
    end
    |> StudentOrgInvitations.create()
  end

  defp invite_student(_params, _opts), do: nil
end
