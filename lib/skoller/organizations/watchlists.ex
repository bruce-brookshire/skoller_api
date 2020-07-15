defmodule Skoller.Organizations.OrgOwnerWatchlistItems.OrgOwnerWatchlistItem do
  use Ecto.Schema

  alias Skoller.Organizations.OrgStudents.OrgStudent
  alias Skoller.Organizations.OrgOwners.OrgOwner

  schema "org_owner_watchlist_items" do
    belongs_to :org_student, OrgStudent
    belongs_to :org_owner, OrgOwner

    timestamps()
  end

  use ExMvc.ModelChangeset, req_fields: ~w[org_student_id org_owner_id]a
end

defmodule Skoller.Organizations.OrgOwnerWatchlistItems do
  use ExMvc.Adapter, model: __MODULE__.OrgOwnerWatchlistItem
end

defmodule Skoller.Organizations.OrgGroupOwnerWatchlistItems.OrgGroupOwnerWatchlistItem do
  use Ecto.Schema

  alias Skoller.Organizations.OrgGroupStudents.OrgGroupStudent
  alias Skoller.Organizations.OrgGroupOwners.OrgGroupOwner

  schema "org_group_owner_watchlist_items" do
    belongs_to :org_group_student, OrgGroupStudent
    belongs_to :org_group_owner, OrgGroupOwner
    
    timestamps()
  end

  use ExMvc.ModelChangeset, req_fields: ~w[org_group_student_id org_group_owner_id]a
end

defmodule Skoller.Organizations.OrgGroupOwnerWatchlistItems do
  use ExMvc.Adapter, model: __MODULE__.OrgGroupOwnerWatchlistItem
end
