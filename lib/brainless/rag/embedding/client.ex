defmodule Brainless.Rag.Embedding.Client do
  @moduledoc """
  See https://www.elastic.co/docs/solutions/search/vector/knn
  """
  use HTTPoison.Base

  alias Brainless.Rag.Embedding.IndexData

  @type search_options ::
          {:k, pos_integer()}
          | {:similarity, float()}
          | {:num_candidates, pos_integer()}
          | {:filter, map()}
          | {:size, pos_integer()}

  # l2_norm, cosine, dot_product, max_inner_product
  @similarity "cosine"
  @default_timeout to_timeout(second: 30)
  @search_size 30
  @search_k 100
  @search_similarity 0.3
  @search_num_candidates 1000

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
    option(:es_url)
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

  @spec create_index(String.t(), map()) :: {:error, any()} | :ok
  def create_index(index_name, meta_mappings) do
    case put!(index_name, %{mappings: get_mappings(meta_mappings)}) do
      %{body: %{"error" => %{"type" => "resource_already_exists_exception"}}} ->
        {:error, :index_already_exists}

      %{body: %{"error" => _}} ->
        {:error, :create_index_error}

      _ ->
        :ok
    end
  end

  @spec delete_index(String.t()) :: {:error, any()} | :ok
  def delete_index(index_name) do
    case delete!(index_name) do
      %{status_code: 200, body: %{"acknowledged" => true}} ->
        :ok

      %{status_code: 404, body: %{"error" => %{"type" => "index_not_found_exception"}}} ->
        {:error, :index_not_found}

      %{status_code: _, body: %{"error" => _}} ->
        {:error, :index_delete_error}
    end
  end

  @spec bulk_index(String.t(), [{IndexData.t(), float()}]) :: {:error, any()} | {:ok, [map()]}
  def bulk_index(index_name, items) do
    payload =
      items
      |> Enum.flat_map(&bulk_unwrap/1)
      |> Enum.reduce([], fn chunk, acc -> ["\n", JSON.encode_to_iodata!(chunk) | acc] end)
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    case put!("#{index_name}/_bulk", payload) do
      %{status_code: 200, body: %{"errors" => false, "items" => items}} ->
        {:ok, items}

      %{status_code: 200, body: %{"errors" => true}} ->
        {:error, :bulk_index_payload_error}

      _ ->
        {:error, :bulk_index_error}
    end
  end

  @spec search(String.t(), [float()], [search_options()]) ::
          {:error, term()} | {:ok, [{map(), float()}]}
  def search(index_name, vector, opts \\ []) do
    url = "#{index_name}/_search"

    params = prepare_search_params(vector, opts)

    case post!(url, params) do
      %{status_code: 200, body: %{"hits" => %{"hits" => hits}}} ->
        {:ok, Enum.map(hits, &extract_search_item/1)}

      _ ->
        {:error, "Unknown error"}
    end
  end

  # See https://www.elastic.co/docs/solutions/search/vector/knn#knn-similarity-search
  # How to invert _score back to the underlying similarity
  #   l2_norm: sqrt((1 / _score) - 1)
  #   cosine: (2 * _score) - 1
  #   dot_product: (2 * _score) - 1
  #   max_inner_product:
  #     _score < 1: 1 - (1 / _score)
  #     _score >= 1: _score - 1
  def invert_score(score, "l2_norm"), do: :math.sqrt(1 / score - 1)
  def invert_score(score, "cosine"), do: 2 * score - 1
  def invert_score(score, "dot_product"), do: 2 * score - 1
  def invert_score(score, "max_inner_product") when score < 1, do: 1 - 1 / score
  def invert_score(score, "max_inner_product") when score >= 1, do: score - 1
  def invert_score(_, _), do: raise("Invalid type")

  defp get_mappings(meta) do
    %{
      properties: %{
        vector: %{
          type: "dense_vector",
          dims: option(:dimensions),
          index: true,
          similarity: @similarity
        },
        content: %{type: "text"},
        meta: %{
          properties: meta
        }
      }
    }
  end

  defp bulk_unwrap({%IndexData{id: id, meta: meta, content: content}, vector}) do
    [
      %{index: %{_id: id}},
      %{vector: vector, content: content, meta: meta}
    ]
  end

  defp apply_filter(base_params, filter) when is_map(filter) do
    Map.put_new(base_params, :filter, filter)
  end

  defp apply_filter(base_params, _), do: base_params

  defp get_knn_params(vector, opts) do
    similarity = Keyword.get(opts, :similarity, @search_similarity)
    k = Keyword.get(opts, :k, @search_k)
    num_candidates = Keyword.get(opts, :num_candidates, @search_num_candidates)

    %{
      query_vector: vector,
      field: "vector",
      similarity: similarity,
      k: k,
      num_candidates: num_candidates
    }
  end

  defp prepare_search_params(vector, opts) do
    filter = Keyword.get(opts, :filter)
    size = Keyword.get(opts, :size, @search_size)

    %{
      knn: vector |> get_knn_params(opts) |> apply_filter(filter),
      size: size
    }
  end

  defp extract_search_item(%{"_source" => %{"meta" => meta}, "_score" => score}),
    do: {meta, invert_score(score, @similarity)}

  defp option(key) when is_atom(key) do
    :brainless
    |> Application.fetch_env!(Brainless.Rag.Embedding)
    |> Keyword.fetch!(key)
  end
end
