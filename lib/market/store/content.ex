defmodule Market.Store.Content do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contents" do
    field :file, :binary
    field :content_type, :string
    field :sender_id, :integer
    field :receiver_id, :integer
    field :is_payable, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:sender_id, :content_type, :receiver_id, :is_payable, :file])
    |> validate_required([:sender_id, :content_type, :receiver_id, :is_payable, :file])
    |> validate_inclusion(:content_type, Market.valid_content_types())
  end
end
