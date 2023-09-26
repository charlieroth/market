defmodule Market.Repo.Migrations.CreatePurchaseTable do
  use Ecto.Migration

  def change do
    create table(:purchases) do
      add :purchase_token, :string
      add :completed, :boolean, default: false, null: false
      add :content_id, :integer
      add :receiver_id, :integer

      timestamps()
    end
  end
end
