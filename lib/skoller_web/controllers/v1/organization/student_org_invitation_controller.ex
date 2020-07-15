defmodule SkollerWeb.Api.V1.Organization.StudentOrgInvitationController do
  alias Skoller.Organizations.{
    StudentOrgInvitations,
    OrgGroupStudents,
    OrgStudents,
    OrgGroups,
    OrgStudents.OrgStudent
  }

  alias SkollerWeb.Organization.StudentOrgInvitationView
  alias Skoller.Services.SesMailer
  alias Skoller.StudentClasses
  alias Skoller.Students

  import SkollerWeb.Plugs.InsightsAuth
  import SkollerWeb.Plugs.Auth

  use ExMvc.Controller,
    adapter: StudentOrgInvitations,
    view: StudentOrgInvitationView,
    only: [:show, :update, :delete]

  @student_role 100

  plug :verify_role, %{role: @student_role} when action in [:respond, :student_invites]
  plug :verify_owner, :student_org_invites when action in [:index, :show, :respond]
  plug :verify_owner, :student when action == :student_invites

  plug :verify_owner,
       :organization when action in [:csv_create, :create, :update, :delete, :email_reminder]

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

  def create(conn, %{"organization_id" => org_id} = params) do
    if Map.has_key?(params, "org_group_id") and not OrgGroups.exists?(id: params["org_group_id"]) do
      send_resp(conn, 422, "Group does not exist")
    else
      case invite_student(params, %{org_id: org_id, group_id: params["org_group_id"]}) do
        {:ok, invite} ->
          conn |> put_view(StudentOrgInvitationView) |> render("invite.json", invite: invite)

        %OrgStudent{} = org_student ->
          conn
          |> put_view(StudentOrgInvitationView)
          |> render("invite.json", org_student: org_student)

        {:error, %{errors: errors}} ->
          body = ExMvc.Controller.stringify_changeset_errors(errors)
          send_resp(conn, 422, body)

        _ ->
          send_resp(conn, 422, "Unprocessable Entity")
      end
    end
  end

  def csv_create(conn, %{"file" => file, "organization_id" => org_id} = params) do
    cond do
      Map.has_key?(params, "org_group_id") and not OrgGroups.exists?(id: params["org_group_id"]) ->
        send_resp(conn, 422, "Group does not exist")

      true ->
        invitations =
          file.path
          |> File.stream!()
          |> CSV.decode(headers: true)
          |> Enum.map(&process_student(&1, %{org_id: org_id, group_id: params["org_group_id"]}))

        conn
        |> put_view(StudentOrgInvitationView)
        |> render("invites.json", invites: invitations)
    end
  end

  def email_reminder(conn, %{"organization_id" => org_id}) do
    StudentOrgInvitations.get_by_params(organization_id: org_id)
    |> Enum.each(fn %{email: email, organization: %{name: org_name}} ->
      send_reminder_email(email, org_name)
    end)

    send_resp(conn, 204, "")
  end

  def student_invites(conn, %{"student_id" => student_id}) do
    invitations = StudentOrgInvitations.get_by_params(student_id: student_id)

    conn
    |> put_view(StudentOrgInvitationView)
    |> render("index.json", models: invitations)
  end

  defp process_student({:ok, params}, opts),
    do: invite_student(params, opts)

  defp process_student(error, _org_id), do: error

  defp invite_student(params, %{org_id: org_id} = opts) do
    group_ids =
      case opts[:group_id] do
        nil -> []
        id when is_integer(id) -> [id]
        id when is_binary(id) -> [String.to_integer(id)]
      end

    params
    |> Map.merge(%{"organization_id" => org_id, "group_ids" => group_ids})
    |> invite_student()
  end

  defp invite_student(_params, _opts), do: nil

  defp invite_student(%{"phone" => phone, "organization_id" => org_id} = params) do
    student = Students.get_student_by_phone(phone)

    cond do
      invitation = invitation_by_params(phone, org_id) ->
        org_group_ids =
          (invitation.group_ids ++ (params["group_ids"] || []))
          |> Enum.uniq()

        invitation |> StudentOrgInvitations.update(%{group_ids: org_group_ids})

      org_student = org_student_by_params(student, org_id) ->
        org_student |> add_org_group_students(params)

      true ->
        student
        |> case do
          nil -> params
          %{id: student_id} -> Map.put(params, "student_id", student_id)
        end
        |> StudentOrgInvitations.create()
    end
  end

  defp org_student_by_params(nil, _org_id), do: nil

  defp org_student_by_params(%{phone: phone}, org_id) do
    student_id = Map.get(Students.get_student_by_phone(phone) || %{}, :id, 0)

    OrgStudents.get_by_params(student_id: student_id, organization_id: org_id)
    |> List.first()
  end

  defp invitation_by_params(phone, org_id),
    do:
      StudentOrgInvitations.get_by_params(phone: phone, organization_id: org_id)
      |> List.first()

  defp add_org_group_students(%{org_groups: groups, id: org_student_id}, params) do
    existing_groups = groups |> Enum.map(& &1.id)

    (groups ++ (params["group_ids"] || []))
    |> Enum.uniq()
    |> Enum.reject(&(&1 in existing_groups))
    |> Enum.map(&%{org_group_id: &1, org_student_id: org_student_id})
    |> Enum.each(&OrgGroupStudents.create/1)

    OrgStudents.get_by_id(org_student_id)
  end

  defp send_invite_email(email, org_name, invited_by) do
    %{
      to: email,
      template_data: %{
        organization_name: org_name,
        invited_by: invited_by
      }
    }
    |> SesMailer.send_individual_email("skoller_insights_invitation")
  end

  defp send_reminder_email(email, org_name) do
    %{
      to: email,
      template_data: %{
        organization_name: org_name
      }
    }
    |> SesMailer.send_individual_email("skoller_insights_reminder")
  end
end
