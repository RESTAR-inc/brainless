defmodule Brainless.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  import Ecto.Query, warn: false

  alias Brainless.MediaLibrary.Book
  alias Brainless.MediaLibrary.Genre
  alias Brainless.MediaLibrary.Movie
  alias Brainless.MediaLibrary.Person
  alias Brainless.Repo

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

  def get_book!(id), do: Repo.get!(Book, id) |> Repo.preload([:authors, :genres])

  @spec get_by_ids(atom(), [pos_integer()]) :: [term()]
  def get_by_ids(:movie, ids) do
    from(movie in Movie, preload: [:cast, :genres])
    |> where([p], p.id in ^ids)
    |> Repo.all()
  end

  def get_by_ids(:book, ids) do
    from(book in Book, preload: [:authors, :genres])
    |> where([p], p.id in ^ids)
    |> Repo.all()
  end

  def get_by_ids(_, _), do: raise(ArgumentError, message: "invalid type")
end
