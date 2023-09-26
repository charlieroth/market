defmodule Market.StoreFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Market.Store` context.
  """

  @doc """
  Generate a content.
  """
  def content_fixture(attrs \\ %{}) do
    {:ok, content} =
      attrs
      |> Enum.into(%{
        file:
          "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
        file_type: "png",
        sender_id: 123,
        receiver_id: 456,
        is_payable: true
      })
      |> Market.Store.create_content()

    content
  end
end
