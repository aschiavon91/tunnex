defmodule Server.StoresSupervisor do
  @moduledoc false

  use Supervisor

  alias Server.External.SocketStore, as: ExternalSocketStore
  alias Server.Internal.SocketStore, as: InternalSocketStore

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      InternalSocketStore,
      ExternalSocketStore
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
