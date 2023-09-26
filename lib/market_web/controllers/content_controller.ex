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
         "file_type" => file_type,
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
             file_type: file_type,
             sender_id: sender_id,
             receiver_id: receiver_id,
             is_payable: is_payable
           }) do
      conn
      |> put_status(:created)
      |> render(:show, content: content)
    else
      reason ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})
    end
  end

  defp handle_create("application/json", conn, %{
         "file" => file_base64,
         "file_type" => file_type,
         "sender_id" => sender_id,
         "receiver_id" => receiver_id,
         "is_payable" => is_payable
       }) do
    with {:ok, file} <- Base.decode64(file_base64),
         {:ok, content} <-
           Store.create_content(%{
             file: file,
             file_type: file_type,
             sender_id: sender_id,
             receiver_id: receiver_id,
             is_payable: is_payable
           }) do
      conn
      |> put_status(:created)
      |> render(:show, content: content)
    else
      reason ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})
    end
  end

  defp handle_create(_other_content_type, conn, _params) do
    conn
    |> put_status(500)
    |> json(%{message: "unknown content type"})
  end

  defp parse_boolean_string("true"), do: true
  defp parse_boolean_string("false"), do: false
  defp parse_boolean_string(_), do: {:error, "invalid boolean string"}

  def content_for_user(conn, %{"user_id" => user_id}) do
    with {user_id, _} <- Integer.parse(user_id),
         {:ok, contents} <- Store.list_contents(%{user_id: user_id}) do
      conn
      |> put_status(200)
      |> render(:index, contents: contents)
    else
      {:error, "No content found"} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "No content found"})

      reason ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})
    end
  end

  def purchase(conn, %{"content_id" => content_id, "user_id" => user_id}) do
    with {content_id, _} <- Integer.parse(content_id),
         content <- Store.get_content!(content_id),
         {:ok, content, purchase_token} <- Store.init_purchase(content, user_id) do
      conn
      |> put_status(:ok)
      |> json(%{purchase_token: purchase_token, content_id: content.id})
    else
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})

      _reason ->
        conn
        |> put_status(500)
        |> json(%{message: "Internal server error"})
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
        |> put_status(:unprocessable_entity)
        |> json(%{message: "Purchase token expired"})

      {:error, :token_mismatch} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{message: "Purchase token could not be found"})

      reason ->
        IO.inspect(reason)

        conn
        |> put_status(500)
        |> json(%{message: "Internal server error"})
    end
  end
end
