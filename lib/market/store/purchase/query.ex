defmodule Market.Store.Purchase.Query do
  import Ecto.Query, warn: false
  alias Market.Store.Purchase

  def base(), do: Purchase

  def filter(query \\ base(), filters) do
    query
    |> filter_by_purchase_id(filters)
    |> filter_by_content_id(filters)
    |> filter_by_receiver_id(filters)
    |> filter_by_completed(filters)
  end

  def filter_by_purchase_id(query, %{purchase_id: purchase_id}) do
    query
    |> where([p], p.id == ^purchase_id)
  end

  def filter_by_purchase_id(query, _filters), do: query

  def filter_by_receiver_id(query, %{receiver_id: receiver_id}) do
    query
    |> where([p], p.receiver_id == ^receiver_id)
  end

  def filter_by_receiver_id(query, _filters), do: query

  def filter_by_content_id(query, %{content_id: content_id}) do
    query
    |> where([p], p.content_id == ^content_id)
  end

  def filter_by_content_id(query, _filters), do: query

  def filter_by_completed(query, %{completed: completed}) do
    query
    |> where([p], p.completed == ^completed)
  end

  def filter_by_completed(query, _filters), do: query
end
