defmodule Classnavapi.Admin.Settings do

  alias Classnavapi.Repo
  alias Classnavapi.Admin.Setting

  import Ecto.Query

  @auto_upd_topic "AutoUpdate"

  def get_auto_update_settings() do
    from(s in Setting)
    |> where([s], s.topic == @auto_upd_topic)
    |> Repo.all()
  end
end