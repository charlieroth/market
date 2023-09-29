defmodule Market.StoreTest do
  use Market.DataCase

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

  defp with_completed_purchase_and_token(%{content: content, user: user}) do
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
        {1, :minute}
      )

    {:ok, purchase} =
      Market.Store.update_purchase(purchase, %{purchase_token: token, completed: true})

    %{content: content, user: user, purchase: purchase, token: token}
  end

  describe "contents" do
    @valid_content_attrs %{
      file:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
      content_type: "image/png",
      sender_id: 123,
      receiver_id: 456,
      is_payable: true
    }

    @invalid_content_attrs %{
      file: nil,
      sender_id: nil,
      content_type: nil,
      receiver_id: nil,
      is_payable: false
    }

    test "list_contents/0 returns all contents" do
      content = content_fixture()
      assert Market.Store.list_contents() == [content]
    end

    test "get_content!/1 returns the content with given id" do
      content = content_fixture()
      assert Market.Store.get_content!(content.id) == content
    end

    test "create_content/1 with valid data creates a content" do
      assert {:ok, %Market.Store.Content{} = content} =
               Market.Store.create_content(@valid_content_attrs)

      assert content.sender_id == 123
      assert content.content_type == "image/png"
      assert content.receiver_id == 456
      assert content.is_payable == true
    end

    test "create_content/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{valid?: false}} =
               Market.Store.create_content(@invalid_content_attrs)
    end

    test "create_content/1 with invalid content_type returns error changeset" do
      assert {:error,
              %Ecto.Changeset{
                valid?: false,
                errors: [
                  content_type:
                    {"is invalid",
                     [
                       validation: :inclusion,
                       enum: [
                         "image/jpeg",
                         "image/png",
                         "image/gif",
                         "application/pdf",
                         "multipart/form-data",
                         "text/plain"
                       ]
                     ]}
                ]
              }} =
               Market.Store.create_content(
                 @valid_content_attrs
                 |> Map.put(:content_type, "png")
               )
    end

    test "update_content/2 with valid data updates the content" do
      content = content_fixture()

      update_attrs = %{
        sender_id: 456,
        content_type: "image/jpeg",
        receiver_id: 123,
        is_payable: false
      }

      assert {:ok, %Market.Store.Content{} = content} =
               Market.Store.update_content(content, update_attrs)

      assert content.sender_id == 456
      assert content.content_type == "image/jpeg"
      assert content.receiver_id == 123
      assert content.is_payable == false
    end

    test "update_content/2 with invalid data returns error changeset" do
      content = content_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Market.Store.update_content(content, @invalid_content_attrs)

      assert content == Market.Store.get_content!(content.id)
    end

    test "delete_content/1 deletes the content" do
      content = content_fixture()
      assert {:ok, %Market.Store.Content{}} = Market.Store.delete_content(content)
      assert_raise Ecto.NoResultsError, fn -> Market.Store.get_content!(content.id) end
    end

    test "change_content/1 returns a content changeset" do
      content = content_fixture()
      assert %Ecto.Changeset{} = Market.Store.change_content(content)
    end
  end

  describe "create_purchase_token/1" do
    setup [:with_user, :with_content, :with_incomplete_purchase]

    test "create_purchase_token/1 returns a token with valid data", %{
      user: user,
      content: content,
      purchase: purchase
    } do
      assert {:ok, _token} =
               Market.Store.create_purchase_token(
                 %{
                   purchase_id: purchase.id,
                   content_id: content.id,
                   receiver_id: user.id
                 },
                 {1, :minute}
               )
    end
  end

  describe "init_purchase/2 incomplete purchase" do
    setup [:with_user, :with_content, :with_incomplete_purchase_and_token]

    test "user can initialize a purchase for a piece of content they are a receiver of", %{
      user: user,
      content: content
    } do
      assert {:ok, _content, _purchase_token} = Market.Store.init_purchase(content, user.id)
    end

    test "user cannot initialize a purchase for a piece of content they are not the receiver of",
         %{
           content: content
         } do
      assert {:error, "Content is not for this receiver"} =
               Market.Store.init_purchase(content, 789)
    end
  end

  describe "init_purchase/2 completed purchase" do
    setup [:with_user, :with_content, :with_completed_purchase_and_token]

    test "Same user cannot initialize purchase of same content twice", %{
      user: user,
      content: content
    } do
      assert {:error, "User already purchased content"} =
               Market.Store.init_purchase(content, user.id)
    end
  end

  describe "complete_purchase/2" do
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
