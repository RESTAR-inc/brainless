defmodule Brainless.Rag.Embedding do
  @moduledoc """
  Root embedding
  """
  use Brainless.Rag.Config

  alias Brainless.Rag.Embedding.IndexData
  alias Brainless.Rag.Embedding.Provider.Gemini
  alias Brainless.Rag.Embedding.Provider.Local

  @spec to_vector(String.t()) :: {:error, term()} | {:ok, [float()]}
  def to_vector(input) do
    case get_rag_config(:embedding_provider) do
      :gemini ->
        Gemini.to_vector(input)

      :local ->
        Local.to_vector(input)
    end
  end

  @spec to_index_list([IndexData.t()]) ::
          {:error, map()} | {:ok, [{IndexData.t(), [float()]}]}
  def to_index_list(data_list) do
    case get_rag_config(:embedding_provider) do
      :gemini ->
        Gemini.to_index_list(data_list)

      :local ->
        Local.to_index_list(data_list)
    end
  end

  def provider do
    get_rag_config(:embedding_provider)
  end
end
