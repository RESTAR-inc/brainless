defmodule Brainless.Rag do
  alias Brainless.Rag.Embedding
  alias Brainless.Rag.Generation
  alias Brainless.Rag.Retrieval

  def generate(provider, query) do
    prompt =
      Embedding.predict(provider, query)
      |> Retrieval.retrieve()
      |> format_prompt(query)

    Generation.predict(provider, prompt)
  end

  defp format_prompt(_context, query) do
    # TODO: add formatted query
    # """
    # Use the following context to respond to the following query.
    # Context:
    # #{Enum.map_join(context, "\n", & &1)}
    # Query: #{query}
    # """

    query
  end
end
