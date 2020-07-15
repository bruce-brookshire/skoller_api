defmodule SkollerWeb.OrganizationView do
  use SkollerWeb, :view

  alias SkollerWeb.LinkView
  alias SkollerWeb.SchoolView
  alias SkollerWeb.OrganizationView

  def render("index-admin.json", %{organizations: organizations}) do
    render_many(organizations, OrganizationView, "organization.json")
  end

  def render("index.json", %{organizations: organizations}) do
    render_many(organizations, OrganizationView, "organization-base.json")
  end

  def render("show.json", %{organization: organization}) do
    render_one(organization, OrganizationView, "organization.json")
  end

  def render("organization-base.json", %{organization: organization}) do
    organization |> Map.take([:id, :name])

    %{
      id: organization.id,
      name: organization.name,
      schools: organization.schools |> school_view()
    }
  end

  def render("organization.json", %{organization: organization}) do
    render_one(organization, OrganizationView, "organization-base.json")
    |> Map.merge(%{
      custom_signup_link: link_view(organization)
    })
  end

  defp link_view(%{custom_signup_link: custom_signup_link}) when not is_nil(custom_signup_link) do
    render_one(custom_signup_link, LinkView, "link_base.json")
  end

  defp link_view(_organization), do: nil

  defp school_view(schools) when is_list(schools),
    do: render_many(schools, SchoolView, "school-min.json")

  defp school_view(%Ecto.Association.NotLoaded{}), do: []
  defp school_view(_), do: nil
end
