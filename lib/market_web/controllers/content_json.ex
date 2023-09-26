defmodule MarketWeb.ContentJSON do
  alias Market.Store.Content

  @doc """
  Renders a list of contents.
  """
  def index(%{contents: contents}) do
    %{data: for(content <- contents, do: data(content))}
  end

  @doc """
  Renders a single content.
  """
  def show(%{content: content}) do
    %{data: data(content)}
  end

  defp data(%Content{} = content) do
    %{
      id: content.id,
      sender_id: content.sender_id,
      file_type: content.file_type,
      receiver_id: content.receiver_id,
      is_payable: content.is_payable
    }
  end
end
