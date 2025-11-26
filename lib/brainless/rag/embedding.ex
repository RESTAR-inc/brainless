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
    case get_provider() do
      :gemini ->
        Gemini.str_to_vector(input,
          dimensions: get_dimensions()
        )

      :local ->
        Local.str_to_vector(input)
    end
  end

  @spec docs_to_index_list(documents :: [EmbedDocument.t()]) ::
          {:error, map()} | {:ok, [EmbedData.t()]}
  def docs_to_index_list(documents) do
    case get_provider() do
      :gemini ->
        Gemini.docs_to_index_list(documents,
          dimensions: get_dimensions()
        )

      :local ->
        Local.docs_to_index_list(documents)
    end
  end

  def get_provider do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :provider)
  end

  def get_dimensions do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :dimensions)
  end
end
