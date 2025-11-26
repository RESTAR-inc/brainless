defmodule Brainless.Rag.Embedding.Client do
  @moduledoc """
  See https://www.elastic.co/docs/solutions/search/vector/knn#knn-similarity-search

  How similarity works:

    l2_norm: sqrt((1 / _score) - 1)
    cosine: (2 * _score) - 1
    dot_product: (2 * _score) - 1
    max_inner_product:
      _score < 1: 1 - (1 / _score)
      _score >= 1: _score - 1
  """
  use HTTPoison.Base

  alias Brainless.Rag.Embedding.EmbedData

  @similarity "cosine"
  @default_timeout to_timeout(second: 30)

  @impl true
  def process_request_options(options) do
    options
    |> Keyword.put_new(:timeout, @default_timeout)
    |> Keyword.put_new(:recv_timeout, @default_timeout)
    |> Keyword.put_new(:hackney, pool: false)
  end

  @impl true
  def process_request_headers(headers) do
    key = "Content-Type"
    List.keystore(headers, key, 0, {key, "application/json; charset=UTF-8"})
  end

  @impl true
  def process_request_url(url) do
    :brainless
    |> Application.fetch_env!(Brainless.Rag.Embedding)
    |> Keyword.fetch!(:elasticsearch_url)
    |> URI.merge(url)
    |> URI.to_string()
  end

  @impl true
  def process_request_body(body) when is_binary(body), do: body
  def process_request_body(body), do: body |> JSON.encode!()

  @impl true
  def process_response_body(body) do
    case JSON.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
  end

  @spec get_mappings(integer(), map()) :: map()
  def get_mappings(dimensions, meta) do
    %{
      properties: %{
        embedding: %{
          type: "dense_vector",
          dims: dimensions,
          index: true,
          similarity: @similarity
        },
        meta: %{
          properties: meta
        }
      }
    }
  end

  @spec delete_index(String.t()) :: any()
  def delete_index(index_name) do
    case delete!(index_name) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  @spec create_index(String.t(), integer(), map()) :: any()
  def create_index(index_name, dimensions, mappings) do
    case put!(index_name, %{mappings: get_mappings(dimensions, mappings)}) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  @spec insert_index(String.t(), String.t(), EmbedData.t()) :: any()
  def insert_index(index_name, id, %EmbedData{meta: meta, embedding: embedding}) do
    payload = %{meta: meta, embedding: embedding}

    case put!("/#{index_name}/_doc/#{id}/", payload) do
      %{body: %{"error" => error}} ->
        {:error, error}

      _ ->
        :ok
    end
  end
end
