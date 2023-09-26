defmodule Market.StoreTest do
  use Market.DataCase

  alias Market.Store

  describe "contents" do
    alias Market.Store.Content

    import Market.StoreFixtures

    @invalid_attrs %{sender_id: nil, file_type: nil, receiver_id: nil, is_payable: false}

    test "list_contents/0 returns all contents" do
      content = content_fixture()
      assert Store.list_contents() == [content]
    end

    test "get_content!/1 returns the content with given id" do
      content = content_fixture()
      assert Store.get_content!(content.id) == content
    end

    test "create_content/1 with valid data creates a content" do
      valid_attrs = %{sender_id: 42, file_type: "png", receiver_id: 42, is_payable: true}

      assert {:ok, %Content{} = content} = Store.create_content(valid_attrs)
      assert content.sender_id == 42
      assert content.file_type == "png"
      assert content.receiver_id == 42
      assert content.is_payable == true
    end

    test "create_content/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Store.create_content(@invalid_attrs)
    end

    test "update_content/2 with valid data updates the content" do
      content = content_fixture()

      update_attrs = %{
        sender_id: 43,
        file_type: "jpeg",
        receiver_id: 43,
        is_payable: false
      }

      assert {:ok, %Content{} = content} = Store.update_content(content, update_attrs)
      assert content.sender_id == 43
      assert content.file_type == "jpeg"
      assert content.receiver_id == 43
      assert content.is_payable == false
    end

    test "update_content/2 with invalid data returns error changeset" do
      content = content_fixture()
      assert {:error, %Ecto.Changeset{}} = Store.update_content(content, @invalid_attrs)
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
end
