defmodule Market.Repo.Migrations.MakePurchaseTokenText do
  use Ecto.Migration

  def change do
    alter table(:purchases) do
      modify :purchase_token, :text
    end
  end
end
