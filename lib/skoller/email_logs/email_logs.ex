defmodule Skoller.EmailLogs do
  @moduledoc """
  A context module for the email logs
  """

  alias Skoller.Repo
  alias Skoller.EmailLogs.EmailLog

  import Ecto.Query

  @doc """
  Gets all email log entries for a user and an email type

  ## Returns
  `[%Skoller.EmailLogs.EmailLog]` or `[]`
  """
  def get_sent_emails_by_user_and_type(user_id, email_type_id) do
    from(l in EmailLog)
    |> where([l], l.user_id == ^user_id and l.email_type_id == ^email_type_id)
    |> Repo.all()
  end

  def log_email(user_id, email_type_id),
    do: Repo.insert(%EmailLog{user_id: user_id, email_type_id: email_type_id})
end
