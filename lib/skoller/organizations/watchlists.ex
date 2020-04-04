defmodule Skoller.Organizations.Watchlists.OrgOwnerWatchlistItems do
  use Ecto.Schema


  alias Skoller.Organizations.OrgStudents.OrgStudent
  alias Skoller.Organizations.OrgOwners.OrgOwner

  schema "org_owner_watchlist_items" do
    belongs_to :org_student, OrgStudent
    belongs_to :org_owner, OrgOwner
  end
end

defmodule Skoller.Organizations.Watchlists.OrgGroupOwnerWatchlistItems do
  use Ecto.Schema


  alias Skoller.Organizations.OrgGroupStudents.OrgGroupStudent
  alias Skoller.Organizations.OrgGroupOwners.OrgGroupOwner

  schema "org_group_owner_watchlist_items" do
    belongs_to :group_student, OrgGroupStudent
    belongs_to :org_group_owner, OrgGroupOwner
  end
end