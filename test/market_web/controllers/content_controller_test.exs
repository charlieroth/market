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
          file_type: "png",
          sender_id: 678,
          receiver_id: 123,
          is_payable: false
        })

      assert %{
               "id" => _id,
               "file_type" => _file_type,
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
          file_type: "png",
          sender_id: 678,
          receiver_id: 123,
          is_payable: false
        })

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns 400 when given unsupported content-type", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "text/html")
        |> post(~p"/api/content", %{
          file:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
          file_type: "png",
          sender_id: 678,
          receiver_id: 123,
          is_payable: false
        })

      assert conn.status == 400
    end
  end

  describe "get receiver content" do
    setup [:with_user, :with_content]

    test "returns content for given user", %{conn: conn, content: content, user: user} do
      conn = get(conn, ~p"/api/user/#{user.id}/content")

      assert json_response(conn, 200)["data"] == [
               %{
                 "file_type" => "png",
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
      content: content,
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
      content: content,
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
end
