defmodule Brainless.Rag.Embedding.Provider.Gemini do
  @moduledoc """
    See https://developers.googleblog.com/en/gemini-embedding-available-gemini-api/
  """
  use Brainless.Rag.Embedding.Provider

  alias Brainless.Rag.Embedding.IndexData

  @impl true
  def to_vector(input, opts) do
    model = Keyword.get(opts, :model)
    dimensions = Keyword.get(opts, :dimensions)

    ReqLLM.embed(model, input, dimensions: dimensions)
  end

  @impl true
  def to_index_list(data_list, opts) do
    model = Keyword.get(opts, :model)
    dimensions = Keyword.get(opts, :dimensions)

    texts = Enum.map(data_list, & &1.content)

    case ReqLLM.embed(model, texts, dimensions: dimensions) do
      {:ok, embeds} ->
        result = Enum.zip_with([data_list, embeds], &zip_embeds/1)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp zip_embeds([%IndexData{} = input, vector]),
    do: {input, vector}
end
