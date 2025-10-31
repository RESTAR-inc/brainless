defmodule Brainless.Rag do
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Generation
  alias Brainless.MediaLibrary
  alias Brainless.MediaLibrary.Movie

  def generate(query) when is_binary(query) do
    with {:ok, vector} <- Embedding.to_vector(query),
         movies <- MediaLibrary.retrieve_movies(vector, preload: [:director, :cast, :genres]),
         {:ok, response} <- format_prompt(movies, query) |> Generation.generate() do
      {:ok, movies, response}
    else
      reason -> {:error, reason}
    end
  end

  def generate(query, movies) when is_binary(query) and is_list(movies) do
    with {:ok, response} <- format_prompt(movies, query) |> Generation.generate() do
      {:ok, movies, response}
    else
      reason -> {:error, reason}
    end
  end

  def format_prompt(movies, query) do
    # TODO: add formatted query
    """
    Use the following context to respond to the following query.
    Context:
    #{Enum.map_join(movies, "\n", &Movie.format_for_embedding(&1))}

    # Query: #{query}
    """
  end

  def to_vector(text) when is_binary(text), do: Embedding.to_vector(text)

  def to_vector_list(texts) when is_list(texts), do: Embedding.to_vector_list(texts)
end
