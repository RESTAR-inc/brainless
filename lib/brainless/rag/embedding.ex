defmodule Brainless.Rag.Embedding do
  @moduledoc """
  Root embedding
  """
  alias Brainless.Rag.Embedding.EmbedData
  alias Brainless.Rag.Embedding.EmbedDocument
  alias Brainless.Rag.Embedding.Provider.Gemini
  alias Brainless.Rag.Embedding.Provider.Local

  @spec str_to_vector(input :: String.t()) :: {:error, term()} | {:ok, [float()]}
  def str_to_vector(input) do
    case provider() do
      :gemini ->
        Gemini.str_to_vector(input,
          model: option(:gemini_model),
          dimensions: dimensions()
        )

      :local ->
        Local.str_to_vector(input,
          dimensions: dimensions(),
          api_key: option(:api_key),
          service_url: option(:service_url)
        )
    end
  end

  @spec docs_to_index_list(documents :: [EmbedDocument.t()]) ::
          {:error, map()} | {:ok, [EmbedData.t()]}
  def docs_to_index_list(documents) do
    case provider() do
      :gemini ->
        Gemini.docs_to_index_list(documents,
          model: option(:gemini_model),
          dimensions: dimensions()
        )

      :local ->
        Local.docs_to_index_list(documents,
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
