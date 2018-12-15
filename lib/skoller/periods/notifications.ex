defmodule Skoller.Periods.Notifications do
  @moduledoc """
  A context module for class period notifications
  """

  alias Skoller.Periods
  alias Skoller.Periods.Devices
  alias Skoller.Services.Notification

  @period_prompt_category "ClassPeriod.Prompt"
  @period_prompt_text " is coming up! If you join classes now, you can see who your classmates are 👀 👫 "

  @doc """
  Sends a notification to users in a period that just got changed to the
  prompt status.
  """
  def prompt_for_future_enrollment_notification(period) do
    next_period = Periods.get_next_period_for_school(period.school_id)
    Devices.get_devices_by_period(period.id)
    |> Enum.each(&Notification.create_notification(&1.udid, &1.type, next_period.name <> @period_prompt_text, @period_prompt_category))
  end
end