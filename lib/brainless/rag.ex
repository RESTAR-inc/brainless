defmodule Brainless.Rag do
  @moduledoc """
  Main RAG module
  """

  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Document.MediaDocument
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Embedding.Client
  alias Brainless.Rag.Prediction
  alias Brainless.Rag.Reranking
  alias Brainless.Rag.Response

  @module_map %{
    media: Brainless.Rag.Document.MediaDocument
  }

  def search(module_key, query, opts \\ []) when is_binary(query) do
    use_ai_summary = Keyword.get(opts, :use_ai_summary, false)
    top_n = Keyword.get(opts, :top_n, 20)

    with {:ok, mod} <- Map.fetch(@module_map, module_key),
         {:ok, vector} <- Embedding.to_vector(query),
         {:ok, items} <- Client.search(mod, vector, opts),
         {:ok, reranked_items} <- rerank(mod, items, query, top_n),
         results <- mod.retrieve(reranked_items),
         {:ok, results, ai_response} <- predict(use_ai_summary, results, query) do
      response = %Response{
        query: query,
        results: results,
        ai_response: ai_response
      }

      {:ok, response}
    else
      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :rag_search_error}
    end
  end

  defp rerank(_mod, [], _, _top_n), do: {:ok, []}

  defp rerank(_mod, index_data_list, query, top_n) do
    case Reranking.rerank(index_data_list, query, top_n: top_n) do
      {:ok, items} ->
        {:ok, items}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp predict(true, results, query) do
    prompt = format_prompt(results, query)

    case Prediction.predict(prompt) do
      {:ok, ai_response} ->
        {:ok, results, ai_response}

      {:error, _} ->
        {:ok, results, nil}
    end
  end

  defp predict(false, results, _query) do
    {:ok, results, nil}
  end

  defp format_entity({%Movie{} = movie, "movie", _}), do: MediaDocument.format(movie)
  defp format_entity({%Book{} = book, "book", _}), do: MediaDocument.format(book)
  defp format_entity(_), do: ""

  defp format_prompt(items, query) do
    """
    You are an AI assistant for a media library application.
    Perform an analysis of the data to determine whether it matches the user’s prompt and pick top 5 matches.

    User Prompt: `#{query}`

    Use the following context to respond to the following prompt:

    ```
    #{Enum.map_join(items, "\n", &format_entity(&1))}
    ```
    """
  end
end
