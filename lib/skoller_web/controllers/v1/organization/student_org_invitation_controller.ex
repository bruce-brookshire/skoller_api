defmodule SkollerWeb.Api.V1.Organization.StudentOrgInvitationController do
  alias Skoller.Organizations.StudentOrgInvitations
  alias SkollerWeb.Organization.StudentOrgInvitationView
  alias Skoller.Organizations.OrgStudents
  alias Skoller.Repo

  import SkollerWeb.Plugs.InsightsAuth

  use ExMvc.Controller,
    adapter: StudentOrgInvitations,
    view: StudentOrgInvitationView

  plug(:verify_owner, :student_org_invites when action in [:index, :get, :update]) 

  # def index(%{assigns: %{user: user}} = conn, %{"organization_id" => organization_id}) do
  #   case user do
  #     %{student: %{id: id}} ->
  #       invites =
  #         StudentOrgInvitations.get_by_params(student_id: id, organization_id: organization_id)

  #       put_view(conn, StudentOrgInvitationView)
  #       |> render("index.json", models: invites)

  #     %{roles: roles} ->
  #       case Enum.any?(roles, &(&1.id == 700 || &1.id == 200)) do
  #         true ->
  #           invites = StudentOrgInvitations.get_by_params(organization_id: organization_id)

  #           put_view(conn, StudentOrgInvitationView)
  #           |> render("index.json", models: invites)

  #         false ->
  #           conn
  #           |> send_resp(401, "unauthorized")
  #       end
  #   end
  # end

  # def respond(conn, %{"student_org_invitation_id" => invite_id, "accepts" => accepts}) do
  #   case StudentOrgInvitations.get_by_id(invite_id) do
  #     nil ->
  #       conn |> send_resp(401, "Not found")

  #     %{student_id: _, organization_id: _} = invite ->
  #       if accepts,
  #         do: Map.take(invite, [:student_id, :organization_id]) |> OrgStudents.create()

  #       StudentOrgInvitations.delete(invite)
  #       send_resp(conn, 204, "")
  #   end
  # end
end
