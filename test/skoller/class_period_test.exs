defmodule Skoller.ClassPeriodTest do
  use Skoller.DataCase

  alias Skoller.Periods.ClassPeriod

  @valid_attrs %{name: "Quarter Name",
                school_id: 1}

  test "class period insert with valid attributes" do
    changeset = ClassPeriod.changeset_insert(%ClassPeriod{}, @valid_attrs)
    assert changeset.valid?
  end

  test "class period insert with no name" do
    changeset = ClassPeriod.changeset_insert(%ClassPeriod{}, Map.delete(@valid_attrs, :name))
    refute changeset.valid?
  end

  test "class period insert with no school" do
    changeset = ClassPeriod.changeset_insert(%ClassPeriod{}, Map.delete(@valid_attrs, :school_id))
    refute changeset.valid?
  end
end