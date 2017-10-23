defmodule Classnavapi.ClassPeriodTest do
  use Classnavapi.DataCase

  alias Classnavapi.ClassPeriod

  @valid_attrs %{end_date: "2018-10-12T18:51:53Z", 
                name: "Quarter Name",
                start_date: "2017-10-12T18:51:53Z", 
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

  test "class period insert with no start date" do
    changeset = ClassPeriod.changeset_insert(%ClassPeriod{}, Map.delete(@valid_attrs, :start_date))
    refute changeset.valid?
  end

  test "class period insert with no end date" do
    changeset = ClassPeriod.changeset_insert(%ClassPeriod{}, Map.delete(@valid_attrs, :end_date))
    refute changeset.valid?
  end

  test "class period insert with start date after end date" do
    changeset = ClassPeriod.changeset_insert(%ClassPeriod{}, %{@valid_attrs | start_date: "2019-10-12T18:51:53Z"})
    refute changeset.valid?
  end
end