defmodule Brainless.Rag.Embedding.Provider.Gemini do
  @moduledoc """
    See https://developers.googleblog.com/en/gemini-embedding-available-gemini-api/
  """
  use Brainless.Rag.Embedding.Provider

  alias Brainless.Rag.Embedding.EmbedData
  alias Brainless.Rag.Embedding.EmbedDocument

  @impl true
  def str_to_vector(input, opts) do
    model = Keyword.get(opts, :model)
    dimensions = Keyword.get(opts, :dimensions)
    ReqLLM.embed(model, input, dimensions: dimensions)
  end

  @impl true
  def docs_to_index_list(documents, opts) do
    model = Keyword.get(opts, :model)
    dimensions = Keyword.get(opts, :dimensions)

    texts = Enum.map(documents, & &1.content)

    case ReqLLM.embed(model, texts, dimensions: dimensions) do
      {:ok, embeddings} ->
        result =
          documents
          |> Enum.zip(embeddings)
          |> Enum.map(fn {%EmbedDocument{meta: meta}, embedding} ->
            %EmbedData{meta: meta, embedding: embedding}
          end)

        {:ok, result}

      {:error, _reason} ->
        {:error, "Unable to create a vector list"}
    end
  end
end
