defmodule Market.Repo.Migrations.MigrateExistingContentTypes do
  use Ecto.Migration

  def change do
    Market.Store.Content
    |> Market.Repo.all()
    |> Enum.each(fn content ->
      new_content_type =
        case content.content_type do
          "jpeg" -> "image/jpg"
          "jpg" -> "image/jpg"
          "png" -> "image/png"
          "gif" -> "image/gif"
          "pdf" -> "application/pdf"
          "multipart/form-data" -> "multipart/form-data"
          "txt" -> "text/plain"
          _ -> "INVALID"
        end

      content
      |> Market.Store.Content.changeset(%{content_type: new_content_type})
      |> Market.Repo.update()
    end)
  end
end
