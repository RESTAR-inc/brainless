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
          |> Enum.map(fn {%EmbedDocument{id: id, meta: meta}, embedding} ->
            %EmbedData{id: id, meta: meta, embedding: embedding}
          end)

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
