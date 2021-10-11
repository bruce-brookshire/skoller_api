defmodule Skoller.Users.Trial do
  @moduledoc false

  alias Skoller.Users.User

  @subscription_module_started ~N[2021-10-10 05:00:18]

  @doc false
  def new_user?(%User{} = user) do
    user.inserted_at > @subscription_module_started
  end

  @doc false
  def start_date(%User{} = user) do
    new_user?(user) && user.inserted_at || @subscription_module_started
  end

  @doc false
  def end_date(%User{} = user) do
    start_date(user)
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.add(60*60*24*30)
  end

  @doc false
  def now?(%User{} = user) do
    end_date(user) < DateTime.now!("Etc/UTC")
  end
end
