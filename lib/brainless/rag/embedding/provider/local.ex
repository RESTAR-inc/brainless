defmodule Brainless.Rag.Embedding.Provider.Local do
  @moduledoc """
  Local embeddings
  """
  use Brainless.Rag.Embedding.Provider

  alias Brainless.Rag.Embedding.EmbedData

  @impl true
  def str_to_vector(input, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    headers = Keyword.get(opts, :api_key) |> get_headers()
    url = Keyword.get(opts, :service_url) |> get_url(:one)

    json = %{
      document: %{content: input, meta: %{}},
      dimensions: dimensions
    }

    case Req.post(url, headers: headers, json: json) do
      {:ok, %Req.Response{body: body}} ->
        data = create_embed_data(body)
        {:ok, data.embedding}

      {:error, _reason} ->
        {:error, "Unable to create a vector"}
    end
  end

  @impl true
  def docs_to_index_list(documents, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    url = Keyword.get(opts, :service_url) |> get_url(:many)
    headers = Keyword.get(opts, :api_key) |> get_headers()

    json = %{
      documents: Enum.map(documents, &%{meta: &1.meta, content: &1.content}),
      dimensions: dimensions
    }

    case Req.post(url, headers: headers, json: json) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, Enum.map(body, &create_embed_data/1)}

      {:error, _reason} ->
        {:error, "Unable to create a vector list"}
    end
  end

  defp create_embed_data(%{"embedding" => embedding, "meta" => meta}) do
    %EmbedData{meta: meta, embedding: embedding}
  end

  defp get_url(service_url, :many), do: "#{service_url}/api/embeddings/many"
  defp get_url(service_url, :one), do: "#{service_url}/api/embeddings/one"

  defp get_headers(api_key) do
    ["x-api-key": api_key]
  end
end
