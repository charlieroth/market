defmodule Market.Store do
  @moduledoc """
  The Store context.
  """

  import Ecto.Query, warn: false
  alias Market.Repo
  alias Market.Store.Content
  alias Market.Store.Purchase

  @doc """
  Returns the list of contents.

  ## Examples

      iex> list_contents(%{user_id: 123})
      [%Content{}, ...]

  """
  def list_contents(%{user_id: user_id}) do
    case Content.Query.for_receiver(user_id) |> Repo.all() do
      [] ->
        {:error, "No content found"}

      contents ->
        {:ok, contents}
    end
  end

  def list_contents(_filters) do
    Content.Query.base() |> Repo.all()
  end

  @doc """
  Returns a piece of content.

  ## Examples

      iex> get_content!(123)
      %Content{}

      iex> get_content!(0)
      {:error, %Ecto.Changeset{}}
  """
  def get_content!(id) do
    Repo.get!(Content, id)
  end

  @doc """
  Create a piece of content.

  ## Examples

      iex> create_content(%{field: value})
      {:ok, %Content{}}

      iex> create_content(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def create_content(%{
        file: file,
        file_type: file_type,
        sender_id: sender_id,
        receiver_id: receiver_id,
        is_payable: is_payable
      }) do
    %Content{}
    |> Content.changeset(%{
      file_type: file_type,
      file: file,
      sender_id: sender_id,
      receiver_id: receiver_id,
      is_payable: is_payable
    })
    |> Repo.insert()
  end

  def create_content(_params) do
    {:error, "Invalid request parameters"}
  end

  @doc """
  Updates a content.

  ## Examples

      iex> update_content(content, %{field: new_value})
      {:ok, %Content{}}

      iex> update_content(content, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_content(%Content{} = content, attrs) do
    content
    |> Content.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a content.

  ## Examples

      iex> delete_content(content)
      {:ok, %Content{}}

      iex> delete_content(content)
      {:error, %Ecto.Changeset{}}

  """
  def delete_content(%Content{} = content) do
    Repo.delete(content)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking content changes.

  ## Examples

      iex> change_content(content)
      %Ecto.Changeset{data: %Content{}}

  """
  def change_content(%Content{} = content, attrs \\ %{}) do
    Content.changeset(content, attrs)
  end

  @doc """
  Initializes a purchase between a user and a piece of content
  """
  @spec init_purchase(content :: Content.t(), user_id :: integer()) ::
          {:ok, Content.t(), String.t()} | {:error, String.t()} | any()
  def init_purchase(%Content{} = content, user_id) do
    case {content.is_payable, content.receiver_id == user_id} do
      {true, true} ->
        # create purchase
        {:ok, purchase} =
          create_purchase(%{
            purchase_token: create_purchase_token(content, user_id),
            completed: false,
            content_id: content.id,
            receiver_id: user_id
          })

        {:ok, content, purchase.purchase_token}

      {false, _} ->
        {:error, "Content is not payable"}

      {_, false} ->
        {:error, "Content is not for this receiver"}
    end
  end

  def create_purchase(attrs \\ %{}) do
    %Purchase{}
    |> Purchase.changeset(attrs)
    |> Repo.insert()
  end

  def get_purchase(id) do
    Repo.get(Purchase, id)
  end

  def update_purchase(%Purchase{} = purchase, attrs) do
    purchase
    |> Purchase.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Calls the payment processor to initialize a purchase.

  Returns a purchase token that expires in 10 minutes.
  """
  @spec create_purchase_token(Content.t(), integer()) :: String.t()
  def create_purchase_token(_content, _receiver_id) do
    # TODO: Call payment processor to initialize purchase
    :crypto.strong_rand_bytes(32) |> Base.encode64(padding: false)
  end

  @doc """
  Completes a purchase between a user and a piece of content
  """
  @spec complete_purchase(integer(), String.t(), integer()) ::
          {:ok, Purchase.t()} | {:error, String.t()} | any()
  def complete_purchase(purchase_id, purchase_token_from_req, user_id) do
    with %Purchase{purchase_token: purchase_token_from_db} = purchase <-
           get_purchase(purchase_id),
         true <- purchase.receiver_id == user_id,
         :ok <- validate_purchase_tokens(purchase_token_from_req, purchase_token_from_db),
         updated_purchase <- update_purchase(purchase, %{completed: true}) do
      {:ok, updated_purchase}
    else
      nil ->
        {:error, "Purchase not found"}

      {:error, "Purchase token expired"} = reason ->
        reason

      reason ->
        reason
    end
  end

  @spec validate_purchase_tokens(String.t(), String.t()) :: :ok | {:error, String.t()}
  def validate_purchase_tokens(purchase_token_from_req, purchase_token_from_db) do
    IO.inspect(purchase_token_from_req, label: "purchase_token_from_req")
    IO.inspect(purchase_token_from_db, label: "purchase_token_from_db")
    # TODO: Implement
    :ok
  end
end
