defmodule MarketWeb.ContentControllerTest do
  use MarketWeb.ConnCase

  import Market.StoreFixtures

  defp with_user(context) do
    Enum.into(context, %{user: %{id: 456}})
  end

  defp with_content(%{user: user} = context) do
    content = content_fixture(%{receiver_id: user.id})
    Enum.into(context, %{content: content})
  end

  defp with_purchase_and_token(%{content: content, user: user} = context) do
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

    Enum.into(%{purchase: purchase, token: token}, context)
  end

  defp with_completed_purchase(%{content: content, user: user} = context) do
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

    {:ok, purchase} =
      Market.Store.update_purchase(purchase, %{purchase_token: token, completed: true})

    Enum.into(%{purchase: purchase, token: token}, context)
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create content" do
    test "renders content when data is valid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/content", %{
          file:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
          content_type: "image/png",
          sender_id: 678,
          receiver_id: 123,
          is_payable: false
        })

      assert %{
               "id" => _id,
               "content_type" => _content_type,
               "sender_id" => _sender_id,
               "is_payable" => _is_payable
             } = json_response(conn, 201)["data"]
    end

    test "returns 422 when given not a bas64 encoded file string", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/content", %{
          file: "not-valid-file-data",
          content_type: "image/png",
          sender_id: 678,
          receiver_id: 123,
          is_payable: false
        })

      assert conn.status == 400
    end

    test "returns 422 status when given a bad content-type", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/content", %{
          file:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
          content_type: "png",
          sender_id: 678,
          receiver_id: 123,
          is_payable: false
        })

      assert conn.status == 422
    end

    test "returns 400 when given unsupported content-type", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "text/html")
        |> post(~p"/api/content", %{
          file:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
          content_type: "image/png",
          sender_id: 678,
          receiver_id: 123,
          is_payable: false
        })

      assert conn.status == 400
    end
  end

  describe "get content user has purchased" do
    setup [:with_user, :with_content, :with_completed_purchase]

    test "returns content for given user", %{conn: conn, content: content, user: user} do
      conn = get(conn, ~p"/api/user/#{user.id}/content/#{content.id}")
      assert conn |> get_resp_header("content-type") |> Enum.at(0) == "image/png; charset=utf-8"
      assert conn.status == 200
    end

    test "return 400 when user has not purchased content requested", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, ~p"/api/user/#{user.id}/content/678")
      assert conn.status == 403
    end

    test "return 400 either user_id is not a valid id", %{
      conn: conn
    } do
      conn = get(conn, ~p"/api/user/not-a-valid-user-id/content/678")
      assert conn.status == 400
    end

    test "return 400 either content_id is not a valid id", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, ~p"/api/user/#{user.id}/content/not-a-valid-content-id")
      assert conn.status == 400
    end
  end

  describe "get receiver content" do
    setup [:with_user, :with_content]

    test "returns 200 and received content for given user", %{
      conn: conn,
      content: content,
      user: user
    } do
      conn = get(conn, ~p"/api/user/#{user.id}/content/received")

      assert json_response(conn, 200)["data"] == [
               %{
                 "content_type" => "image/png",
                 "id" => content.id,
                 "is_payable" => true,
                 "receiver_id" => user.id,
                 "sender_id" => 123
               }
             ]
    end

    test "returns 400 when given an invalid user_id", %{conn: conn} do
      conn = get(conn, ~p"/api/user/not-valid-user-id/content/received")
      assert conn.status == 400
    end
  end

  describe "get purchased content" do
    setup [:with_user, :with_content, :with_completed_purchase]

    test "returns content for given user", %{conn: conn, content: content, user: user} do
      conn = get(conn, ~p"/api/user/#{user.id}/content/purchased")

      assert json_response(conn, 200)["data"] == [
               %{
                 "content_type" => "image/png",
                 "id" => content.id,
                 "is_payable" => true,
                 "receiver_id" => user.id,
                 "sender_id" => 123
               }
             ]
    end
  end

  describe "purchase a piece of content" do
    setup [:with_user, :with_content]

    test "returns a purchase token and content id given valid data", %{
      conn: conn,
      content: content,
      user: user
    } do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/content/#{content.id}/purchase", %{
          user_id: user.id
        })

      response = json_response(conn, 200)
      assert response["content_id"] == content.id
      assert response["purchase_token"] != nil
    end

    test "fails when an invalid content_id is in the URL", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/content/not-a-valid-id/purchase", %{
          user_id: user.id
        })

      assert conn.status == 400
    end

    test "fails content_id not found", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/content/123/purchase", %{
          user_id: user.id
        })

      assert conn.status == 404
    end
  end

  describe "complete a purchase" do
    setup [:with_user, :with_content, :with_purchase_and_token]

    test "successfully completes a purchase", %{
      conn: conn,
      token: token,
      purchase: purchase
    } do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-purchase-token", token)
        |> post(~p"/api/purchase/#{purchase.id}/complete", %{})

      assert conn.status == 200
    end

    test "fails when purchase token is expired", %{
      conn: conn,
      token: token,
      purchase: purchase
    } do
      Process.sleep(3000)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-purchase-token", token)
        |> post(~p"/api/purchase/#{purchase.id}/complete", %{})

      assert conn.status == 400
    end

    test "fails when token on purchase record and purchase token sent in request don't match", %{
      conn: conn,
      purchase: purchase
    } do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-purchase-token", "not-the-same-token")
        |> post(~p"/api/purchase/#{purchase.id}/complete", %{})

      assert conn.status == 400
    end

    test "fails when purchase id is not a valid id", %{
      conn: conn,
      token: token
    } do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-purchase-token", token)
        |> post(~p"/api/purchase/not-valid-id/complete", %{})

      assert conn.status == 400
    end

    test "fails when purchase does not exist", %{
      conn: conn,
      token: token
    } do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-purchase-token", token)
        |> post(~p"/api/purchase/123/complete", %{})

      assert conn.status == 400
    end
  end
end
