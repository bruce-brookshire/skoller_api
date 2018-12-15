defmodule Skoller.Notifications.ManualLogs do
  @moduledoc """
  A context module for manual notification logs
  """

  alias Skoller.Repo
  alias Skoller.Notifications.ManualLog

  @doc """
  Creates a manual log entry, showing that someone has created a manual notification.

  ## Returns
  `{:ok, log}` or `{:error, changeset}`
  """
  def create_manual_log(user_count, category, msg) do
    Repo.insert(%ManualLog{affected_users: user_count, notification_category: category, msg: msg})
  end

  @doc """
  Returns a list of manual log entries
  """
  def get_manual_logs() do
    Repo.all(ManualLog)
  end
end