defmodule Brainless.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  import Ecto.Query, warn: false

  alias Brainless.Repo

  alias Brainless.MediaLibrary.{Genre, Movie, Person}

  @type retrieve_options ::
          {:preload, [atom()]}

  def create_genre(attrs) do
    %Genre{}
    |> Genre.changeset(attrs)
    |> Repo.insert()
  end

  def list_genres do
    Repo.all(Genre)
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
    Repo.all(Movie) |> Repo.preload([:director, :cast, :genres])
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
  def get_movie!(id), do: Repo.get!(Movie, id) |> Repo.preload([:director, :genres, :cast])

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

  @spec retrieve_movies([integer()], [retrieve_options()]) :: [term()]
  def retrieve_movies(ids, opts \\ []) do
    query = from movie in Movie, where: movie.id in ^ids

    Enum.reduce(opts, query, fn
      {:preload, bindings}, query ->
        preload(query, ^bindings)

      _, query ->
        query
    end)
    |> Repo.all()
  end

  def delete_media(%Movie{} = movie), do: Repo.delete(movie)
end
