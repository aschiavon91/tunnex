defmodule Server.Application do
  @moduledoc false

  use Application

  alias Server.External.Stater, as: ExternalStater
  alias Server.External.Supervisor, as: ExternalSupervisor
  alias Server.Internal.Supervisor, as: InternalSupervisor
  alias Server.Stores.Supervisor, as: StoresSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      StoresSupervisor,
      InternalSupervisor,
      ExternalSupervisor,
      ExternalStater
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
