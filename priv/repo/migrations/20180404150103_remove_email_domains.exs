defmodule Skoller.Repo.Migrations.RemoveEmailDomains do
  use Ecto.Migration

  def up do
    drop table(:email_domains)
  end
end
