defmodule Brainless.Query do
  @moduledoc """
  Utils for Ecto
  """
  import Ecto.Query, warn: false

  alias Brainless.Repo

  @spec stream_all(Ecto.Queryable.t(), pos_integer(), keyword()) :: Enumerable.t(list())
  def stream_all(query, batch_size, repo_opts \\ []) do
    Stream.unfold(0, fn
      :done ->
        nil

      new_offset ->
        results =
          query
          |> limit(^batch_size)
          |> offset(^new_offset)
          |> fetch_batch(repo_opts)

        case results do
          [] ->
            nil

          results ->
            {results, new_offset + batch_size}
        end
    end)
  end

  @spec fetch_batch(Ecto.Queryable.t(), keyword()) :: Enumerable.t(any())
  defp fetch_batch(query, opts) do
    Enum.reduce(opts, query, fn
      {:preload, bindings}, query ->
        preload(query, ^bindings)

      {:order_by, bindings}, query ->
        from t in exclude(query, :order_by), order_by: ^bindings

      _, query ->
        query
    end)
    |> Repo.all()
  end
end
