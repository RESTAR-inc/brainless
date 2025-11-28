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
          {:error, term()} | {:ok, [{[term()], String.t()}]}
  def search(index_name, query, opts \\ []) when is_binary(query) do
    with {:ok, vector} <- Embedding.str_to_vector(query),
         {:ok, hits} <- Client.search(index_name, vector, opts),
         results <- map_results(hits),
         prompt <- format_prompt(results, query),
         {:ok, ai_response} <- Prediction.predict(prompt) do
      {:ok, results, ai_response}
    else
      _ -> {:error, "Can not retrieve the data"}
    end
  end

  defp map_results(hits) when is_list(hits) do
    hits
    |> Enum.reduce(%{}, &compose_results/2)
    |> Enum.map(&retrieve_results/1)
    |> List.flatten()
  end

  defp compose_results({%{"id" => id, "type" => type}, _}, acc) do
    Map.update(acc, type, [id], fn existing_list ->
      existing_list ++ [id]
    end)
  end

  defp retrieve_results({"movie" = type, ids}) when is_list(ids) do
    ids
    |> MediaLibrary.retrieve_movies(preload: [:director, :cast, :genres])
    |> Enum.map(&{type, &1})
    |> List.flatten()
  end

  defp retrieve_results({"book" = type, ids}) when is_list(ids) do
    ids
    |> MediaLibrary.retrieve_books(preload: [:authors, :genres])
    |> Enum.map(&{type, &1})
    |> List.flatten()
  end

  defp format_entity({"movie", %Movie{} = movie}), do: MediaDocument.format(movie)
  defp format_entity({"book", %Book{} = book}), do: MediaDocument.format(book)
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
