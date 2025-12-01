defmodule Brainless.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  import Ecto.Query, warn: false

  alias Brainless.Repo

  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Genre
  alias Brainless.MediaLibrary.Movie
  alias Brainless.MediaLibrary.Person

  def create_genre(attrs) do
    %Genre{}
    |> Genre.changeset(attrs)
    |> Repo.insert()
  end

  def list_genres do
    Repo.all(Genre)
  end

  def get_genre_by_name(name) when is_binary(name) do
    Repo.get_by(Genre, name: name)
  end

  def create_person(attrs) do
    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert()
  end

  def update_person(%Person{} = person, attrs) do
    person
    |> Person.changeset(attrs)
    |> Repo.update()
  end

  def get_person_by_name(name) when is_binary(name) do
    Repo.get_by(Person, name: name)
  end

  def list_persons do
    Repo.all(Person)
  end

  @doc """
  Returns the list of movies.

  ## Examples

      iex> list_movies()
      [%Movie{}, ...]

  """
  def list_movies do
    Repo.all(Movie) |> Repo.preload([:cast, :genres])
  end

  @doc """
  Gets a single movie.

  Raises `Ecto.NoResultsError` if the Movie does not exist.

  ## Examples

      iex> get_movie!(123)
      %Movie{}

      iex> get_movie!(456)
      ** (Ecto.NoResultsError)

  """
  def get_movie!(id), do: Repo.get!(Movie, id) |> Repo.preload([:genres, :cast])

  @doc """
  Creates a movie.

  ## Examples

      iex> create_movie(%{field: value})
      {:ok, %Movie{}}

      iex> create_movie(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_movie(attrs) do
    %Movie{}
    |> Movie.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a movie.

  ## Examples

      iex> update_movie(movie, %{field: new_value})
      {:ok, %Movie{}}

      iex> update_movie(movie, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_movie(%Movie{} = movie, attrs) do
    movie
    |> Movie.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking movie changes.

  ## Examples

      iex> change_movie(movie)
      %Ecto.Changeset{data: %Movie{}}

  """
  def change_movie(%Movie{} = movie, attrs \\ %{}) do
    Movie.changeset(movie, attrs)
  end

  def create_book(attrs) do
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end

  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

  @spec retrieve_media(Ecto.Query.t(), [{integer(), float()}], String.t()) ::
          [{term(), String.t(), float()}]
  defp retrieve_media(query, ids_with_score, type) do
    ids = Enum.map(ids_with_score, fn {id, _} -> id end)
    scores_map = Map.new(ids_with_score)

    query
    |> where([p], p.id in ^ids)
    |> Repo.all()
    |> Enum.map(fn entity ->
      score = Map.get(scores_map, entity.id)
      {entity, type, score}
    end)
  end

  def retrieve({"movie" = type, ids_with_score}) do
    from(movie in Movie, preload: [:cast, :genres])
    |> retrieve_media(ids_with_score, type)
  end

  def retrieve({"book" = type, ids_with_score}) do
    from(book in Book, preload: [:authors, :genres])
    |> retrieve_media(ids_with_score, type)
  end

  def delete_media(%Movie{} = movie), do: Repo.delete(movie)
end
