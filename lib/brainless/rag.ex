defmodule Brainless.Rag do
  @moduledoc """
  Main RAG module
  """
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Document.MediaDocument
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Embedding.Client
  alias Brainless.Rag.Prediction

  @spec search(String.t(), String.t(), [keyword()]) ::
          {:error, term()} | {:ok, [{term(), String.t(), float()}], String.t() | nil}
  def search(index_name, query, opts \\ []) when is_binary(query) do
    use_ai = Keyword.get(opts, :use_ai, false)

    with {:ok, vector} <- Embedding.to_vector(query),
         {:ok, hits} <- Client.search(index_name, vector, opts),
         results <- map_results(hits) do
      if use_ai do
        prompt = format_prompt(results, query)

        case Prediction.predict(prompt) do
          {:ok, ai_response} ->
            {:ok, results, ai_response}

          {:error, _} ->
            {:ok, results, nil}
        end
      else
        {:ok, results, nil}
      end
    else
      _ -> {:error, "Can not retrieve the data"}
    end
  end

  defp map_results(hits) when is_list(hits) do
    hits
    |> Enum.reduce(%{}, &compose_results/2)
    |> Enum.map(&MediaLibrary.retrieve/1)
    |> List.flatten()
    |> Enum.sort_by(fn {_, _, score} -> score end, :desc)
  end

  defp compose_results({%{"id" => id, "type" => type}, score}, acc) do
    Map.update(acc, type, [{id, score}], fn existing_list ->
      existing_list ++ [{id, score}]
    end)
  end

  defp format_entity({%Movie{} = movie, "movie", _}), do: MediaDocument.format(movie)
  defp format_entity({%Book{} = book, "book", _}), do: MediaDocument.format(book)
  defp format_entity(_), do: ""

  defp format_prompt(items, query) do
    """
    Use the following context to respond to the following query.
    Context:
    #{Enum.map_join(items, "\n", &format_entity(&1))}
    # Query:
      #{query}
    """
  end
end
