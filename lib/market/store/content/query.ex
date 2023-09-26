defmodule Market.Store.Content.Query do
  import Ecto.Query, warn: false
  alias Market.Store.Content

  def base(), do: Content

  def for_receiver(query \\ base(), receiver_id) do
    query |> where([c], c.receiver_id == ^receiver_id)
  end

  def for_sender(query \\ base(), sender_id) do
    query |> where([c], c.sender_id == ^sender_id)
  end
end
