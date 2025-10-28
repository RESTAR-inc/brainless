defmodule Mix.Tasks.BuildIndex do
  @moduledoc "Build vector index"

  use Mix.Task

  alias Brainless.Shop

  @requirements ["app.start"]

  def run(_) do
    Shop.list_books()
    |> Enum.each(fn book ->
      # TODO: update indexes
      dbg(book.name)
    end)
  end
end
