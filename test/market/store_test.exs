defmodule Market.StoreTest do
  use Market.DataCase

  alias Market.Store

  describe "contents" do
    alias Market.Store.Content

    import Market.StoreFixtures

    @valid_content_attrs %{
      file:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
      file_type: "png",
      sender_id: 123,
      receiver_id: 456,
      is_payable: true
    }

    @invalid_content_attrs %{
      file: nil,
      sender_id: nil,
      file_type: nil,
      receiver_id: nil,
      is_payable: false
    }

    test "list_contents/0 returns all contents" do
      content = content_fixture()
      assert Store.list_contents() == [content]
    end

    test "get_content!/1 returns the content with given id" do
      content = content_fixture()
      assert Store.get_content!(content.id) == content
    end

    test "create_content/1 with valid data creates a content" do
      assert {:ok, %Content{} = content} = Store.create_content(@valid_content_attrs)
      assert content.sender_id == 123
      assert content.file_type == "png"
      assert content.receiver_id == 456
      assert content.is_payable == true
    end

    test "create_content/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{valid?: false}} =
               Store.create_content(@invalid_content_attrs)
    end

    test "update_content/2 with valid data updates the content" do
      content = content_fixture()

      update_attrs = %{
        sender_id: 456,
        file_type: "jpeg",
        receiver_id: 123,
        is_payable: false
      }

      assert {:ok, %Content{} = content} = Store.update_content(content, update_attrs)
      assert content.sender_id == 456
      assert content.file_type == "jpeg"
      assert content.receiver_id == 123
      assert content.is_payable == false
    end

    test "update_content/2 with invalid data returns error changeset" do
      content = content_fixture()
      assert {:error, %Ecto.Changeset{}} = Store.update_content(content, @invalid_content_attrs)
      assert content == Store.get_content!(content.id)
    end

    test "delete_content/1 deletes the content" do
      content = content_fixture()
      assert {:ok, %Content{}} = Store.delete_content(content)
      assert_raise Ecto.NoResultsError, fn -> Store.get_content!(content.id) end
    end

    test "change_content/1 returns a content changeset" do
      content = content_fixture()
      assert %Ecto.Changeset{} = Store.change_content(content)
    end
  end

  describe "create_purchase_token/1" do
    alias Market.Store.Purchase
    import Market.StoreFixtures

    defp with_user(_context), do: %{user: %{id: 456}}

    defp with_content(%{user: user}) do
      content = content_fixture()
      %{content: content, user: user}
    end

    defp with_incomplete_purchase(%{content: content, user: user}) do
      {:ok, purchase} =
        Market.Store.create_purchase(%{
          completed: false,
          content_id: content.id,
          receiver_id: user.id
        })

      %{content: content, user: user, purchase: purchase}
    end

    setup [:with_user, :with_content, :with_incomplete_purchase]

    test "create_purchase_token/1 returns a token with valid data", %{
      user: user,
      content: content,
      purchase: purchase
    } do
      assert {:ok, _token} =
               Market.Store.create_purchase_token(%{
                 purchase_id: purchase.id,
                 content_id: content.id,
                 receiver_id: user.id
               })
    end
  end

  describe "complete_purchase/2" do
    alias Market.Store.Purchase
    import Market.StoreFixtures

    defp with_user(_context), do: %{user: %{id: 456}}

    defp with_content(%{user: user}) do
      content = content_fixture(%{receiver_id: user.id})
      %{content: content, user: user}
    end

    defp with_incomplete_purchase_and_token(%{content: content, user: user}) do
      {:ok, purchase} =
        Market.Store.create_purchase(%{
          completed: false,
          content_id: content.id,
          receiver_id: user.id
        })

      {:ok, token} =
        Market.Store.create_purchase_token(
          %{
            purchase_id: purchase.id,
            content_id: content.id,
            receiver_id: user.id
          },
          {2, :second}
        )

      {:ok, purchase} = Market.Store.update_purchase(purchase, %{purchase_token: token})

      %{content: content, user: user, purchase: purchase, token: token}
    end

    setup [:with_user, :with_content, :with_incomplete_purchase_and_token]

    test "complete_purchase/2 returns success", %{
      purchase: purchase,
      token: token
    } do
      assert {:ok, _purchase} = Market.Store.complete_purchase(purchase.id, token)
    end

    test "complete_purchase/2 returns error if tokens are not the same", %{
      purchase: purchase
    } do
      assert {:error, :token_mismatch} =
               Market.Store.complete_purchase(purchase.id, "not-the-same-token")
    end

    test "complete_purchase/2 returns error if token is expired", %{
      purchase: purchase,
      token: token
    } do
      Process.sleep(3000)

      assert {:error, :token_expired} =
               Market.Store.complete_purchase(purchase.id, token)
    end
  end
end
