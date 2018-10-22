defmodule Skoller.Services.Formatter do
  @moduledoc """
  Formats strings
  """

  @doc """
  Converts a phone from the database to a human readable string
  """
  def phone_to_string(phone) do
    (phone |> String.slice(0, 3)) <> "-" <> (phone |> String.slice(3, 3)) <> "-" <> (phone |> String.slice(6, 4))
  end

  @doc """
  Converts a naive date time to a human readable string.

  Output format is `YYYY-MM-DD HH:MM:SS`
  """
  def naive_date_to_string(naive_date_time) do
    date_time = DateTime.from_naive!(naive_date_time, "Etc/UTC")
    {:ok, time} = Time.new(date_time.hour, date_time.minute, date_time.second)
    date = DateTime.to_date(date_time)

    to_string(date) <> " " <> to_string(time)
  end
end