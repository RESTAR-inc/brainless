defmodule Brainless.Rag.Embedding do
  @moduledoc """
  Root embedding
  """
  alias Brainless.Rag.Embedding.IndexData
  alias Brainless.Rag.Embedding.Provider.Gemini
  alias Brainless.Rag.Embedding.Provider.Local

  @spec to_vector(String.t()) :: {:error, term()} | {:ok, [float()]}
  def to_vector(input) do
    case provider() do
      :gemini ->
        Gemini.to_vector(input,
          model: option(:gemini_model),
          dimensions: dimensions()
        )

      :local ->
        Local.to_vector(input,
          dimensions: dimensions(),
          api_key: option(:api_key),
          service_url: option(:service_url)
        )
    end
  end

  @spec to_index_list([IndexData.t()]) ::
          {:error, map()} | {:ok, [{IndexData.t(), [float()]}]}
  def to_index_list(data_list) do
    case provider() do
      :gemini ->
        Gemini.to_index_list(data_list,
          model: option(:gemini_model),
          dimensions: dimensions()
        )

      :local ->
        Local.to_index_list(data_list,
          dimensions: dimensions(),
          api_key: option(:api_key),
          service_url: option(:service_url)
        )
    end
  end

  def provider, do: option(:provider)
  def dimensions, do: option(:dimensions)
  defp option(key), do: :brainless |> Application.fetch_env!(__MODULE__) |> Keyword.fetch!(key)
end
