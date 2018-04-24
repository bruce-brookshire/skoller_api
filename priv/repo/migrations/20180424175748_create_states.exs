defmodule Skoller.Repo.Migrations.CreateStates do
  use Ecto.Migration
  alias Skoller.Repo
  alias Skoller.Locations.State

  def up do
    create table(:states) do
      add :state_code, :string
      add :name, :string

      timestamps()
    end
    flush()

    Repo.insert!(%State{state_code: "AK", name: "Alaska"})
    Repo.insert!(%State{state_code: "AL", name: "Alabama"})
    Repo.insert!(%State{state_code: "AR", name: "Arkansas"})
    Repo.insert!(%State{state_code: "AZ", name: "Arizona"})
    Repo.insert!(%State{state_code: "CA", name: "California"})
    Repo.insert!(%State{state_code: "CO", name: "Colorado"})
    Repo.insert!(%State{state_code: "CT", name: "Connecticut"})
    Repo.insert!(%State{state_code: "DC", name: "Washington, D.C."})
    Repo.insert!(%State{state_code: "DE", name: "Delaware"})
    Repo.insert!(%State{state_code: "FL", name: "Florida"})
    Repo.insert!(%State{state_code: "GA", name: "Georgia"})
    Repo.insert!(%State{state_code: "HI", name: "Hawaii"})
    Repo.insert!(%State{state_code: "IA", name: "Iowa"})
    Repo.insert!(%State{state_code: "ID", name: "Idaho"})
    Repo.insert!(%State{state_code: "IL", name: "Illinois"})
    Repo.insert!(%State{state_code: "IN", name: "Indiana"})
    Repo.insert!(%State{state_code: "KS", name: "Kansas"})
    Repo.insert!(%State{state_code: "KY", name: "Kentucky"})
    Repo.insert!(%State{state_code: "LA", name: "Louisiana"})
    Repo.insert!(%State{state_code: "MA", name: "Massachusetts"})
    Repo.insert!(%State{state_code: "MD", name: "Maryland"})
    Repo.insert!(%State{state_code: "ME", name: "Maine"})
    Repo.insert!(%State{state_code: "MI", name: "Michigan"})
    Repo.insert!(%State{state_code: "MN", name: "Minnesota"})
    Repo.insert!(%State{state_code: "MO", name: "Missouri"})
    Repo.insert!(%State{state_code: "MS", name: "Mississippi"})
    Repo.insert!(%State{state_code: "MT", name: "Montana"})
    Repo.insert!(%State{state_code: "NC", name: "North Carolina"})
    Repo.insert!(%State{state_code: "ND", name: "North Dakota"})
    Repo.insert!(%State{state_code: "NE", name: "Nebraska"})
    Repo.insert!(%State{state_code: "NH", name: "New Hampshire"})
    Repo.insert!(%State{state_code: "NJ", name: "New Jersey"})
    Repo.insert!(%State{state_code: "NM", name: "New Mexico"})
    Repo.insert!(%State{state_code: "NV", name: "Nevada"})
    Repo.insert!(%State{state_code: "NY", name: "New York"})
    Repo.insert!(%State{state_code: "OH", name: "Ohio"})
    Repo.insert!(%State{state_code: "OK", name: "Oklahoma"})
    Repo.insert!(%State{state_code: "OR", name: "Oregon"})
    Repo.insert!(%State{state_code: "PA", name: "Pennsylvania"})
    Repo.insert!(%State{state_code: "RI", name: "Rhode Island"})
    Repo.insert!(%State{state_code: "SC", name: "South Carolina"})
    Repo.insert!(%State{state_code: "SD", name: "South Dakota"})
    Repo.insert!(%State{state_code: "TN", name: "Tennessee"})
    Repo.insert!(%State{state_code: "TX", name: "Texas"})
    Repo.insert!(%State{state_code: "UT", name: "Utah"})
    Repo.insert!(%State{state_code: "VA", name: "Virginia"})
    Repo.insert!(%State{state_code: "VT", name: "Vermont"})
    Repo.insert!(%State{state_code: "WA", name: "Washington"})
    Repo.insert!(%State{state_code: "WI", name: "Wisconsin"})
    Repo.insert!(%State{state_code: "WV", name: "West Virginia"})
    Repo.insert!(%State{state_code: "WY", name: "Wyoming"})
  end

  def down do
    drop table(:states)
  end
end
