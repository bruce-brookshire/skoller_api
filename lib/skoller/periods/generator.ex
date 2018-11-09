defmodule Skoller.Periods.Generator do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "class_period_generators" do
    field :end_day, :integer
    field :end_month, :integer
    field :is_main_period, :boolean, default: false
    field :name_prefix, :string
    field :start_day, :integer
    field :start_month, :integer

    timestamps()
  end

  @doc false
  def changeset(generator, attrs) do
    generator
    |> cast(attrs, [:start_month, :start_day, :end_month, :end_day, :name_prefix, :is_main_period])
    |> validate_required([:start_month, :start_day, :end_month, :end_day, :name_prefix, :is_main_period])
  end
end
