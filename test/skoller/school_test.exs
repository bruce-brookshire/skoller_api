defmodule Skoller.SchoolTest do
  use Skoller.DataCase

  alias Skoller.Schools.School

  @valid_attrs %{adr_locality: "Nashville",
                adr_line_1: "530 Church St", 
                adr_line_2: "Suite 405", 
                adr_region: "TN", 
                adr_zip: "6158675309",
                is_readonly: true,
                name: "HKU",
                timezone: "-8",
                adr_country: "us"}

  test "school insert with valid attributes" do
    changeset = School.changeset_insert(%School{}, @valid_attrs)
    assert changeset.valid?
  end

  test "school insert without optional adr line 2" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_line_2))
    assert changeset.valid?
  end

  test "school insert without editable flag" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :is_readonly))
    assert changeset.valid?
  end

  test "school insert without optional city" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_city))
    assert changeset.valid?
  end

  test "school insert without optional adr line 1" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_line_1))
    assert changeset.valid?
  end

  test "school insert without optional state" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_state))
    assert changeset.valid?
  end

  test "school insert without optional zip code" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_zip))
    assert changeset.valid?
  end

  test "school insert with no name" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :name))
    refute changeset.valid?
  end

  test "school insert with no timezone" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :timezone))
    assert changeset.valid?
  end
end