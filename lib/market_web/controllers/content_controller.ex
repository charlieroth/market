defmodule MarketWeb.ContentController do
  use MarketWeb, :controller

  alias Market.Store

  action_fallback MarketWeb.FallbackController

  @doc """
  Upload a piece of content.

  This request handler can accept either a multipart/form-data request or a
  application/json request.
  """
  def upload(conn, params) do
    conn
    |> get_req_header("content-type")
    |> Enum.at(0)
    |> handle_upload(conn, params)
  end

  defp handle_upload("multipart/form-data" <> _rest, conn, %{
         "file" => upload,
         "file_type" => file_type,
         "sender_id" => sender_id_string,
         "receiver_id" => receiver_id_string,
         "is_payable" => is_payable_string
       }) do
    with {sender_id, _} <- Integer.parse(sender_id_string),
         {receiver_id, _} <- Integer.parse(receiver_id_string),
         is_payable <- parse_boolean_string(is_payable_string),
         {:ok, file} <- File.read(upload.path) do
      case Store.create_content(%{
             file: file,
             file_type: file_type,
             sender_id: sender_id,
             receiver_id: receiver_id,
             is_payable: is_payable
           }) do
        {:ok, content} ->
          conn
          |> put_status(:created)
          |> render(:show, content: content)
      end
    else
      reason ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})
    end
  end

  defp handle_upload("application/json", conn, %{
         "file" => file_base64,
         "file_type" => file_type,
         "sender_id" => sender_id,
         "receiver_id" => receiver_id,
         "is_payable" => is_payable
       }) do
    with {:ok, file} <- Base.decode64(file_base64) do
      case Store.create_content(%{
             file: file,
             file_type: file_type,
             sender_id: sender_id,
             receiver_id: receiver_id,
             is_payable: is_payable
           }) do
        {:ok, content} ->
          conn
          |> put_status(:created)
          |> render(:show, content: content)
      end
    end
  end

  defp handle_upload(_other_content_type, conn, _params) do
    conn
    |> put_status(500)
    |> json(%{message: "unknown content type"})
  end

  defp parse_boolean_string("true"), do: true
  defp parse_boolean_string("false"), do: false
  defp parse_boolean_string(_), do: {:error, "invalid boolean string"}

  def content_for_receiver(conn, %{"receiver_id" => receiver_id}) do
    with {receiver_id, _} <- Integer.parse(receiver_id) do
      contents = Store.list_contents(%{receiver_id: receiver_id})
      render(conn, :index, contents: contents)
    else
      reason ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})
    end
  end

  def content_for_sender(conn, %{"sender_id" => sender_id}) do
    with {sender_id, _} <- Integer.parse(sender_id) do
      contents = Store.list_contents(%{sender_id: sender_id})
      render(conn, :index, contents: contents)
    else
      reason ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})
    end
  end

  def update(conn, %{"id" => id, "params" => params}) do
    with content <- Store.get_content!(id),
         {:ok, content} <- Store.update_content(content, params) do
      conn
      |> put_status(:ok)
      |> render(:show, content: content)
    else
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(MarketWeb.ErrorView, "422.json", %{errors: reason})
    end
  end

  def show(conn, %{"id" => id}) do
    content = Store.get_content!(id)
    render(conn, :show, content: content)
  end
end
