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

  def list_contents() do
    Content.Query.base() |> Repo.all()
  end

  @spec purchased_content_for_user(integer()) :: [Content.t()]
  def purchased_content_for_user(user_id) do
    completed_purchases_content_ids =
      Purchase.Query.base()
      |> where([p], p.receiver_id == ^user_id and p.completed == true)
      |> Repo.all()
      |> Enum.map(& &1.content_id)

    Content.Query.base()
    |> where([c], c.id in ^completed_purchases_content_ids)
    |> Repo.all()
  end

  @spec received_content_for_user(integer()) :: [Content.t()]
  def received_content_for_user(user_id) do
    Content.Query.for_receiver(user_id) |> Repo.all()
  end

  @spec user_has_purchased?(user_id :: integer(), content_id :: integer()) :: boolean()
  def user_has_purchased?(user_id, content_id) do
    %{content_id: content_id, receiver_id: user_id, completed: true}
    |> Purchase.Query.filter()
    |> Repo.exists?()
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

  def get_content(id), do: Repo.get(Content, id)

  @doc """
  Create a piece of content.
  """
  @spec create_content(map()) :: {:ok, Content.t()} | {:error, Ecto.Changeset.t()}
  def create_content(
        %{
          file: _file,
          content_type: _content_type,
          sender_id: _sender_id,
          receiver_id: _receiver_id,
          is_payable: _is_payable
        } = attrs
      ) do
    %Content{}
    |> Content.changeset(attrs)
    |> Repo.insert()
  end

  def create_content(_params) do
    {:error, "Invalid content creation attributes"}
  end

  @doc """
  Updates a piece of content
  """
  @spec update_content(Content.t(), map()) :: {:ok, Content.t()} | {:error, Ecto.Changeset.t()}
  def update_content(%Content{} = content, attrs) do
    content
    |> Content.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a piece of content
  """
  @spec delete_content(Content.t()) :: :ok | {:error, Ecto.Changeset.t()}
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
    user_already_purchased? =
      %{content_id: content.id, receiver_id: user_id, completed: true}
      |> Purchase.Query.filter()
      |> Repo.exists?()

    case {user_already_purchased?, content.is_payable, content.receiver_id == user_id} do
      {true, _, _} ->
        {:error, "User already purchased content"}

      {false, true, true} ->
        # create purchase
        {:ok, purchase} =
          create_purchase(%{
            completed: false,
            content_id: content.id,
            receiver_id: user_id
          })

        {:ok, token} =
          create_purchase_token(
            %{
              purchase_id: purchase.id,
              content_id: content.id,
              receiver_id: user_id
            },
            {10, :minute}
          )

        {:ok, purchase} = update_purchase(purchase, %{purchase_token: token})

        {:ok, content, purchase.purchase_token}

      {false, false, _} ->
        {:error, "Content is not payable"}

      {false, _, false} ->
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

  def list_purchases(filters) do
    case Purchase.Query.filter(filters) |> Repo.all() do
      [] ->
        {:error, "No purchases found"}

      purchases ->
        {:ok, purchases}
    end
  end

  def update_purchase(%Purchase{} = purchase, attrs) do
    purchase
    |> Purchase.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates a JWT token to complete a purchase later on.
  """
  @spec create_purchase_token(
          %{
            purchase_id: integer(),
            content_id: integer(),
            receiver_id: integer()
          },
          ttl :: tuple()
        ) :: {:ok, String.t()} | {:error, any()}
  def create_purchase_token(
        %{purchase_id: _purchase_id, content_id: _content_id, receiver_id: _receiver_id} = attrs,
        ttl
      ) do
    case Market.Guardian.encode_and_sign(attrs, %{}, ttl: ttl) do
      {:ok, token, _claims} ->
        {:ok, token}

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Completes a purchase between a user and a piece of content
  """
  @spec complete_purchase(integer(), String.t()) ::
          {:ok, Purchase.t()} | {:error, atom()} | any()
  def complete_purchase(purchase_id, purchase_token_from_req) do
    with %Purchase{purchase_token: purchase_token_from_db} = purchase <-
           get_purchase(purchase_id),
         :ok <- validate_purchase_tokens(purchase_token_from_req, purchase_token_from_db),
         updated_purchase <- update_purchase(purchase, %{completed: true}) do
      {:ok, updated_purchase}
    else
      nil ->
        {:error, :purchase_not_found}

      {:error, :token_expired} ->
        {:error, :token_expired}

      reason ->
        reason
    end
  end

  @doc """
  Validates the purchase tokens from the request and the database
  """
  @spec validate_purchase_tokens(String.t(), String.t()) :: :ok | {:error, String.t()}
  def validate_purchase_tokens(purchase_token_from_req, purchase_token_from_db) do
    with true <- purchase_token_from_req == purchase_token_from_db,
         {:ok, _claims} <- Market.Guardian.decode_and_verify(purchase_token_from_req) do
      :ok
    else
      {:error, :token_expired} ->
        {:error, :token_expired}

      false ->
        {:error, :token_mismatch}
    end
  end
end
