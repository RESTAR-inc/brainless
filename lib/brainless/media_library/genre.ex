defmodule Brainless.MediaLibrary.Genre do
  @moduledoc """
  Genre schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "genres" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = person, attrs) do
    person
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
