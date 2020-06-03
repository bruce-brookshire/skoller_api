defmodule SkollerWeb.Api.V1.Organization.StudentOrgInvitationController do
  alias Skoller.Organizations.StudentOrgInvitations
  alias SkollerWeb.Organization.StudentOrgInvitationView
  alias Skoller.Organizations.OrgStudents
  alias Skoller.Organizations.OrgGroups
  alias Skoller.Organizations.OrgGroupStudents
  alias Skoller.StudentClasses
  alias Skoller.Students
  alias SkollerWeb.CSVView

  import SkollerWeb.Plugs.InsightsAuth
  import SkollerWeb.Plugs.Auth

  use ExMvc.Controller,
    adapter: StudentOrgInvitations,
    view: StudentOrgInvitationView,
    only: [:show, :update, :delete]

  @student_role 100

  plug :verify_role, %{role: @student_role} when action == :respond
  plug :verify_owner, :student_org_invites when action in [:index, :show, :respond]
  plug :verify_owner, :organization when action in [:csv_create, :create, :update, :delete]

  @colors [
    "ae77bdff",
    "e882acff",
    "3484e3ff",
    "61d8a0ff",
    "19a394ff",
    "f1aa39ff",
    "e2762dff",
    "d73f76ff"
  ]

  def index(%{assigns: %{user: %{student_id: student_id}}} = conn, %{
        "organization_id" => organization_id
      })
      when not is_nil(student_id) do
    invites =
      StudentOrgInvitations.get_by_params(
        student_id: student_id,
        organization_id: organization_id
      )

    put_view(conn, StudentOrgInvitationView)
    |> render("index.json", models: invites)
  end

  def index(conn, %{"organization_id" => organization_id}) do
    invites = StudentOrgInvitations.get_by_params(organization_id: organization_id)

    put_view(conn, StudentOrgInvitationView)
    |> render("index.json", models: invites)
  end

  def respond(conn, %{"student_org_invitation_id" => invite_id, "accepts" => accepts}) do
    case StudentOrgInvitations.get_by_id(invite_id) do
      nil ->
        conn |> send_resp(404, "Not found")

      %{student_id: student_id, organization_id: _, class_ids: classes, group_ids: groups} =
          invite ->
        if accepts do
          {:ok, %{id: org_student_id}} =
            Map.take(invite, [:student_id, :organization_id]) |> OrgStudents.create()

          classes
          |> Enum.each(
            &StudentClasses.enroll_in_class(student_id, &1, %{
              "color" => Enum.random(@colors),
              "class_id" => &1,
              "student_id" => student_id
            })
          )

          groups
          |> Enum.each(
            &OrgGroupStudents.create(%{org_student_id: org_student_id, org_group_id: &1})
          )
        end

        StudentOrgInvitations.delete(invite)
        send_resp(conn, 204, "")

      _ ->
        send_resp(conn, 401, "Student profile does not exist")
    end
  end

  def create(conn, params) do
    case invite_student(params) do
      {:ok, invite} ->
        put_view(conn, StudentOrgInvitationView) |> render("show.json", model: invite)

      {:error, %{errors: errors}} ->
        body = ExMvc.Controller.stringify_changeset_errors(errors)
        send_resp(conn, 422, body)

      _ ->
        send_resp(conn, 422, "Unprocessable Entity")
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

  defp invite_student(%{"phone" => phone} = params) do
    case Students.get_student_by_phone(phone) do
      %{id: student_id} -> Map.put(params, "student_id", student_id)
      nil -> params
    end
    |> StudentOrgInvitations.create()
  end

  defp invite_student(params, %{org_id: org_id} = opts) do
    group_ids =
      case Map.has_key?(opts, :group_id) and not is_nil(opts.group_id) do
        true -> [opts.group_id]
        false -> []
      end

    params
    |> Map.merge(%{"organization_id" => org_id, "group_ids" => group_ids})
    |> invite_student()
  end

  defp invite_student(_params, _opts), do: nil
end
