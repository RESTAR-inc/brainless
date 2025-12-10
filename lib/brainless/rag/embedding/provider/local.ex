defmodule Brainless.Rag.Embedding.Provider.Local do
  @moduledoc """
  Local embeddings
  """
  use Brainless.Rag.Embedding.Provider

  alias Brainless.Rag.Embedding.IndexData

  @impl true
  def to_vector(input, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    headers = Keyword.get(opts, :api_key) |> get_headers()
    url = Keyword.get(opts, :service_url) |> endpoint(:one)

    json = %{
      content: input,
      dimensions: dimensions
    }

    case Req.post(url, headers: headers, json: json) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def to_index_list(data_list, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    url = Keyword.get(opts, :service_url) |> endpoint(:bulk)
    headers = Keyword.get(opts, :api_key) |> get_headers()

    json = %{
      documents: Enum.map(data_list, &%{id: &1.id, content: &1.content}),
      dimensions: dimensions
    }

    case Req.post(url, headers: headers, json: json) do
      {:ok, %Req.Response{status: 200, body: embeds}} ->
        result =
          [data_list, embeds]
          |> Enum.zip_with(&zip_embeds/1)
          |> Enum.reject(&is_nil/1)

        {:ok, result}

      {:ok, %Req.Response{status: 422}} ->
        {:error, :embedding_validation_error}

      {:error, _} ->
        {:error, :embedding_error}
    end
  end

  defp zip_embeds([%IndexData{id: id} = input, %{"id" => id, "vector" => vector}]),
    do: {input, vector}

  defp zip_embeds(_), do: nil

  defp endpoint(service_url, :one), do: "#{service_url}/api/embeddings"
  defp endpoint(service_url, :bulk), do: "#{service_url}/api/embeddings/bulk"

  defp get_headers(api_key) do
    [
      "x-api-key": api_key,
      "content-type": ["application/json"]
    ]
  end
end
