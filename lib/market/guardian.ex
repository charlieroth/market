defmodule Market.Guardian do
  use Guardian, otp_app: :market

  def subject_for_token(%{id: id}, _claims) do
    {:ok, id}
  end

  def subject_for_token(_, _), do: {:error, :unsupported_subject_for_token}

  def resource_from_claims(%{"sub" => id}) do
    # TODO: Get purchase
    purchase = Market.Store.get_purchase(id)
    {:ok, purchase}
  end

  def resource_from_claims(_claims), do: {:error, :unsupported_resource_from_claims}
end
