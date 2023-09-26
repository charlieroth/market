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

  def purchase_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{completed: false, content_id: 1, receiver_id: 456})
    {:ok, purchase} = Market.Store.create_purchase(attrs)

    {:ok, token, _claims} =
      Market.Guardian.encode_and_sign(%{
        purchase_id: purchase.id,
        content_id: purchase.content_id,
        receiver_id: purchase.receiver_id
      })

    {:ok, purchase} = Market.Store.update_purchase(purchase, %{purchase_token: token})
    purchase
  end
end
