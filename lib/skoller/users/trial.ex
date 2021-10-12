defmodule Skoller.Users.Trial do
  @moduledoc false

  alias Skoller.Users.User

  # @doc false
  def now?(%User{} = user) do
    user.trial_end > DateTime.now!("Etc/UTC")
  end

  def start_trial_for_all_users do
    Skoller.Repo.update_all(
      User, set: [
        trial_start: DateTime.utc_now,
        trial_end: DateTime.utc_now |> DateTime.add(60*60*24*30)
      ]
    )
  end
end
