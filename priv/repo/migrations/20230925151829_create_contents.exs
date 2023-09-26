defmodule Market.Repo.Migrations.CreateContents do
  use Ecto.Migration

  def change do
    create table(:contents) do
      add :sender_id, :integer
      add :file_type, :string
      add :receiver_id, :integer
      add :is_payable, :boolean, default: false, null: false
      add :file, :binary

      timestamps()
    end
  end
end
