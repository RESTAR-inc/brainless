defmodule Brainless.Rag do
  @moduledoc """
  Main RAG module
  """
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Prediction

  def predict(query) when is_binary(query) do
    with {:ok, vector} <- Embedding.to_vector(query),
         movies <- MediaLibrary.retrieve_movies(vector, preload: [:director, :cast, :genres]),
         prompt <- format_prompt(movies, query),
         {:ok, response} <- Prediction.predict(prompt) do
      {:ok, movies, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def predict(query, movies) when is_binary(query) and is_list(movies) do
    with prompt <- format_prompt(movies, query),
         {:ok, response} <- Prediction.predict(prompt) do
      {:ok, movies, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_prompt(movies, query) do
    """
    Use the following context to respond to the following query.
    Context:
    #{Enum.map_join(movies, "\n", &Movie.format_for_embedding(&1))}

    # Query: #{query}
    """
  end
end
