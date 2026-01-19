defmodule Brainless.Rag.Reranking do
  @moduledoc """
  Reranking module for RAG searches
  """

  use Brainless.Rag.Config

  alias Brainless.Rag.Embedding.IndexData

  @spec rerank([{IndexData.t(), float()}], String.t(), keyword()) ::
          {:error, term()} | {:ok, [{IndexData.t(), float()}]}
  def rerank(items, query, opts) do
    top_n = Keyword.get(opts, :top_n)

    json = %{
      n: top_n,
      query: query,
      documents: Enum.map(items, &prepare_document/1)
    }

    case Req.post(endpoint(), headers: headers(), body: JSON.encode!(json)) do
      {:ok, %Req.Response{status: 200, body: body}} when is_list(body) ->
        result = merge_results(body, items)
        {:ok, result}

      {:ok, %Req.Response{status: 422}} ->
        {:error, :rag_reranking_validation_error}

      {:ok, _} ->
        {:error, :rag_invalid_request}

      {:error, _} ->
        {:error, :rag_reranking_error}
    end
  end

  defp prepare_document({%IndexData{id: id, content: content}, _}) do
    %{id: id, content: content}
  end

  defp merge_results(results, items) do
    items_map =
      items
      |> Enum.map(fn {%IndexData{id: id} = data, _} -> {id, data} end)
      |> Map.new()

    results
    |> Enum.map(fn %{"id" => id, "score" => score} ->
      {Map.get(items_map, id), score}
    end)
  end

  defp endpoint, do: "#{get_rag_config(:service_url)}/api/reranking/bulk"

  defp headers do
    [
      "x-api-key": get_rag_config(:service_api_key),
      "content-type": ["application/json"]
    ]
  end
end
