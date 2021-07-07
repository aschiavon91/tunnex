defmodule Server.Stores.Supervisor do
  @moduledoc false

  use Supervisor

  alias Server.Stores.{IPSocket, Socket}

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      IPSocket,
      Socket
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
