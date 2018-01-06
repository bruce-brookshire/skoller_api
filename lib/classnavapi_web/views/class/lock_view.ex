defmodule ClassnavapiWeb.Class.LockView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.LockView
  alias ClassnavapiWeb.Class.Lock.SectionView
  alias ClassnavapiWeb.UserView

  def render("index.json", %{locks: locks}) do
    render_many(locks, LockView, "lock.json")
  end

  def render("lock.json", %{lock: %{lock: lock, user: user}}) do
    lock = lock |> Repo.preload(:class_lock_section)
    %{
      is_completed: lock.is_completed,
      class_lock_section: render_one(lock.class_lock_section, SectionView, "section.json"),
      user: render_one(user, UserView, "user.json")
    }
  end
end
