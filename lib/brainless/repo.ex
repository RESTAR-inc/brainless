defmodule Brainless.Repo do
  use Ecto.Repo,
    otp_app: :brainless,
    adapter: Ecto.Adapters.Postgres
end
