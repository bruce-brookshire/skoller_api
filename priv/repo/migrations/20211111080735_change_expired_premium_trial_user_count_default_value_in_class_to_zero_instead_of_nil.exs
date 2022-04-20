defmodule Skoller.Repo.Migrations.ChangeExpiredPremiumTrialUserCountDefaultValueInClassToZeroInsteadOfNil do
  use Ecto.Migration

  def up do
    alter table(:classes) do
      modify :premium, :integer, default: 0
      modify :trial, :integer, default: 0
      modify :expired, :integer, default: 0
    end
  end

  def down do
    alter table(:classes) do
      modify :premium, :integer, default: nil
      modify :trial, :integer, default: nil
      modify :expired, :integer, default: nil
    end
  end
end
