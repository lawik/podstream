defmodule Podstream.Repo do
  use Ecto.Repo,
    otp_app: :podstream,
    adapter: Ecto.Adapters.SQLite3
end
