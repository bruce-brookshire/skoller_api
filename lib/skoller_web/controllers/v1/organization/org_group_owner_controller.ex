defmodule SkollerWeb.Api.V1.Organization.OrgGroupOwnerController do
  alias Skoller.Organizations.OrgGroupOwners
  alias SkollerWeb.Organization.OrgOwnerView

  use ExMvc.Controller, adapter: OrgGroupOwners, view: OrgOwnerView

  def group_owners_for_org(conn, %{"organization_id" => org_id} = params) do
    OrgGroupOwners.get_by_params(params)
    |> case do
      owners when is_list(owners) ->
        conn
        |> put_view(OrgOwnerView)
        |> render("index.json", models: owners)

      _ ->
        conn
        |> send_resp(422, "Unprocessable Entity")
    end
  end
end
