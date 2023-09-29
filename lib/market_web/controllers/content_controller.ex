defmodule MarketWeb.ContentController do
  use MarketWeb, :controller

  alias Market.Store

  action_fallback MarketWeb.FallbackController

  @doc """
  Create a piece of content.

  This request handler can accept either a multipart/form-data request or a
  application/json request.
  """
  def create(conn, params) do
    conn
    |> get_req_header("content-type")
    |> Enum.at(0)
    |> handle_create(conn, params)
  end

  defp handle_create("multipart/form-data" <> _rest, conn, %{
         "file" => upload,
         "content_type" => content_type,
         "sender_id" => sender_id_string,
         "receiver_id" => receiver_id_string,
         "is_payable" => is_payable_string
       }) do
    with {sender_id, _} <- Integer.parse(sender_id_string),
         {receiver_id, _} <- Integer.parse(receiver_id_string),
         is_payable <- parse_boolean_string(is_payable_string),
         {:ok, file} <- File.read(upload.path),
         {:ok, content} <-
           Store.create_content(%{
             file: file,
             content_type: content_type,
             sender_id: sender_id,
             receiver_id: receiver_id,
             is_payable: is_payable
           }) do
      conn
      |> put_status(:created)
      |> render(:show, content: content)
    else
      :error ->
        conn
        |> put_status(400)
        |> json(%{errors: "Failed to parse sender_id, receiver_id"})

      {:error, _posix} ->
        conn
        |> put_status(500)
        |> json(%{errors: "Server failed to process uploaded"})

      reason ->
        reason
    end
  end

  defp handle_create("application/json", conn, %{
         "file" => file_base64,
         "content_type" => content_type,
         "sender_id" => sender_id,
         "receiver_id" => receiver_id,
         "is_payable" => is_payable
       }) do
    with {:ok, file} <- Base.decode64(file_base64),
         {true, true} <- {is_integer(sender_id), is_integer(receiver_id)},
         is_payable <-
           if(is_binary(is_payable), do: parse_boolean_string(is_payable), else: is_payable),
         {:ok, content} <-
           Store.create_content(%{
             file: file,
             content_type: content_type,
             sender_id: sender_id,
             receiver_id: receiver_id,
             is_payable: is_payable
           }) do
      conn
      |> put_status(:created)
      |> render(:show, content: content)
    else
      {false, false} ->
        conn
        |> put_status(400)
        |> json(%{errors: "Failed to parse sender_id and receiver_id"})

      {_, false} ->
        conn
        |> put_status(400)
        |> json(%{errors: "Failed to parse receiver_id"})

      {false, _} ->
        conn
        |> put_status(400)
        |> json(%{errors: "Failed to parse sender_id"})

      {:error, "invalid boolean string"} ->
        conn
        |> put_status(400)
        |> json(%{errors: "Failed to parse is_payable"})

      :error ->
        conn
        |> put_status(400)
        |> json(%{errors: "Failed to parse file"})

      reason ->
        reason
    end
  end

  defp handle_create(_other_content_type, conn, _params) do
    conn
    |> put_status(400)
    |> json(%{message: "unsupported request content-type"})
  end

  defp parse_boolean_string("true"), do: {:ok, true}
  defp parse_boolean_string("false"), do: {:ok, false}
  defp parse_boolean_string(_), do: {:error, "invalid boolean string"}

  def content_for_user(conn, %{"content_id" => content_id, "user_id" => user_id}) do
    with {content_id, _} <- Integer.parse(content_id),
         {user_id, _} <- Integer.parse(user_id),
         true <- Store.user_has_purchased?(user_id, content_id),
         %Store.Content{} = content <- Store.get_content(content_id) do
      conn
      |> put_resp_content_type(content.content_type)
      |> send_resp(200, content.file)
    else
      false ->
        conn
        |> put_status(403)
        |> json(%{error: "User has not purchased content"})

      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Failed to find content"})

      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "Failed to parse content_id or user_id"})

      reason ->
        IO.inspect(reason, label: "GET /api/user/:user_id/content/:content_id failed")

        conn
        |> put_status(500)
        |> json(%{error: "Internal server error"})
    end
  end

  def purchased_content_for_user(conn, %{"user_id" => user_id}) do
    with {user_id, _} <- Integer.parse(user_id) do
      case Store.purchased_content_for_user(user_id) do
        [_content | _] = contents ->
          conn
          |> put_status(200)
          |> render(:index, contents: contents)

        [] ->
          conn
          |> put_status(200)
          |> render(:index, contents: [])
      end
    else
      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "Failed to parse user_id"})

      _reason ->
        conn
        |> put_status(500)
        |> json(%{errors: "Internal server error"})
    end
  end

  def received_content_for_user(conn, %{"user_id" => user_id}) do
    with {user_id, _} <- Integer.parse(user_id) do
      case Store.received_content_for_user(user_id) do
        [_content | _] = contents ->
          conn
          |> put_status(200)
          |> render(:index, contents: contents)

        [] ->
          conn
          |> put_status(200)
          |> render(:index, contents: [])
      end
    else
      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "Failed to parse user_id"})

      _reason ->
        conn
        |> put_status(500)
        |> json(%{errors: "Internal server error"})
    end
  end

  def purchase(conn, %{"content_id" => content_id, "user_id" => user_id}) do
    with {content_id, _} <- Integer.parse(content_id),
         %Store.Content{} = content <- Store.get_content(content_id),
         {:ok, content, purchase_token} <- Store.init_purchase(content, user_id) do
      conn
      |> put_status(:ok)
      |> json(%{purchase_token: purchase_token, content_id: content.id})
    else
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{error: reason})

      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "Failed to parse content_id or user_id"})

      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Failed to find content"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(500)
        |> json(%{errors: changeset.errors})
    end
  end

  def complete_purchase(conn, %{"purchase_id" => purchase_id}) do
    with [purchase_token | _] <- get_req_header(conn, "x-purchase-token"),
         {purchase_id, _} <- Integer.parse(purchase_id),
         {:ok, _purchase} <- Store.complete_purchase(purchase_id, purchase_token) do
      conn
      |> put_status(:ok)
      |> json(%{message: "Purchase completed"})
    else
      {:error, :token_expired} ->
        conn
        |> put_status(400)
        |> json(%{error: "Purchase token expired"})

      {:error, :token_mismatch} ->
        conn
        |> put_status(400)
        |> json(%{error: "Purchase token could not be found"})

      {:error, :purchase_not_found} ->
        conn
        |> put_status(400)
        |> json(%{error: "Purchase not found with id: #{purchase_id}"})

      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "Failed to parse purchase_id"})

      _reason ->
        conn
        |> put_status(500)
        |> json(%{error: "Internal server error"})
    end
  end
end
