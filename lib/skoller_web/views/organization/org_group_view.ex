defmodule SkollerWeb.Organization.OrgGroupView do
  alias Skoller.Organizations.OrgGroups.OrgGroup

  use SkollerWeb.View, model: OrgGroup, single_atom: :org_group, plural_atom: :org_groups
end
