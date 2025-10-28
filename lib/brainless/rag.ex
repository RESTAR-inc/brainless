defmodule Brainless.Rag do
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Generation
  alias Brainless.Rag.Retrieval

  def generate(query) do
    Embedding.predict(query)
    |> Retrieval.retrieve()
    |> format_prompt(query)
    |> Generation.predict()
  end

  defp format_prompt(context, query) do
    """
    Use the following context to respond to the following query.
    Context:
    #{Enum.map_join(context, "\n", & &1)}
    Query: #{query}
    """
  end
end
