defmodule Market.Store do
  @moduledoc """
  The Store context.
  """

  import Ecto.Query, warn: false
  alias Market.Repo
  alias Market.Store.Content

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
end
