defmodule Market.Repo.Migrations.ChangeFileTypeToContentType do
  use Ecto.Migration

  def change do
    rename table(:contents), :file_type, to: :content_type
  end
end
