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
      content: input,
      dimensions: dimensions
    }

    case Req.post(url, headers: headers, json: json) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, body}

      {:error, _reason} ->
        {:error, "Unable to create a vector"}
    end
  end

  @impl true
  def docs_to_index_list(documents, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    url = Keyword.get(opts, :service_url) |> get_url(:bulk)
    headers = Keyword.get(opts, :api_key) |> get_headers()

    json = %{
      documents: Enum.map(documents, &%{id: &1.id, meta: &1.meta, content: &1.content}),
      dimensions: dimensions
    }

    case Req.post(url, headers: headers, json: json) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, Enum.map(body, &create_embed_data/1)}

      {:ok, %Req.Response{status: 422}} ->
        {:error, "Validation error"}

      {:ok, _response} ->
        {:error, "Unable to create a vector list"}

      {:error, _reason} ->
        {:error, "Network error"}
    end
  end

  defp create_embed_data(%{"id" => id, "embedding" => embedding, "meta" => meta}) do
    %EmbedData{id: id, meta: meta, embedding: embedding}
  end

  defp get_url(service_url, :one), do: "#{service_url}/api/embeddings"
  defp get_url(service_url, :bulk), do: "#{service_url}/api/embeddings/bulk"

  defp get_headers(api_key) do
    ["x-api-key": api_key]
  end
end
