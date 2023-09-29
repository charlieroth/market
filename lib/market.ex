defmodule Market do
  @moduledoc """
  Market keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @spec is_valid_content_type?(String.t()) :: boolean()
  def is_valid_content_type?(content_type) when is_binary(content_type) do
    content_type in valid_content_types()
  end

  def is_valid_content_type?(_content_type), do: false

  def valid_content_types() do
    [
      "image/jpeg",
      "image/png",
      "image/gif",
      "application/pdf",
      "multipart/form-data",
      "text/plain"
    ]
  end
end
