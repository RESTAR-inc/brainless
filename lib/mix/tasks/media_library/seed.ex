defmodule Mix.Tasks.MediaLibrary.Seed do
  @moduledoc "Seed the database"

  use Mix.Task

  alias Brainless.Tasks.SeedBooks
  alias Brainless.Tasks.SeedMovies

  @requirements ["app.start"]

  def run(_opts) do
    Logger.configure(level: :info)
    SeedBooks.seed()
    SeedMovies.seed()
  end
end
