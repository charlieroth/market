defmodule Market.Store.Purchase do
  use Ecto.Schema
  import Ecto.Changeset

  schema "purchases" do
    field :purchase_token, :string
    field :completed, :boolean
    field :content_id, :integer
    field :receiver_id, :integer

    timestamps()
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:purchase_token, :completed, :content_id, :receiver_id])
    |> validate_required([:completed, :content_id, :receiver_id])
  end
end
