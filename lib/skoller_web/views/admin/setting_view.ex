defmodule SkollerWeb.Admin.SettingView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Admin.SettingView

  def render("index.json", %{settings: settings}) do
    render_many(settings, SettingView, "setting.json")
  end

  def render("show.json", %{setting: setting}) do
    render_one(setting, SettingView, "setting.json")
  end

  def render("setting.json", %{setting: setting}) do
    %{
      name: setting.name,
      value: setting.value
    }
  end
end