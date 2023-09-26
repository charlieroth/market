defmodule Market.Guardian do
  use Guardian, otp_app: :market

  def subject_for_token(
        %{purchase_id: purchase_id, content_id: content_id, receiver_id: receiver_id},
        _claims
      ) do
    sub = "purchase:#{purchase_id}:content:#{content_id}:receiver:#{receiver_id}"
    {:ok, sub}
  end

  def subject_for_token(_, _), do: {:error, :unsupported_subject_for_token}

  def resource_from_claims(%{"sub" => sub}) do
    [_, purchase_id, _, content_id, _, receiver_id] = String.split(sub, ":")

    content_id =
      content_id
      |> Integer.parse()
      |> elem(0)
      |> Market.Store.get_content!()

    receiver_id =
      receiver_id
      |> Integer.parse()
      |> elem(0)

    purchase_id =
      purchase_id
      |> Integer.parse()
      |> elem(0)

    {:ok, purchases} =
      %{content_id: content_id, receiver_id: receiver_id, purchase_id: purchase_id}
      |> Market.Store.list_purchases()

    cond do
      Enum.empty?(purchases) ->
        {:error, :purchase_not_found}

      length(purchases) > 1 ->
        {:error, :multiple_purchases_found}

      true ->
        {:ok, Enum.at(purchases, 0)}
    end
  end

  def resource_from_claims(_claims), do: {:error, :unsupported_resource_from_claims}
end
