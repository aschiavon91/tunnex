defmodule Server.Application do
  @moduledoc false

  use Application

  alias Server.Internal.Listener, as: InternalListener
  alias Server.External.Listener, as: ExternalListener
  alias Server.Stores.{IPSocket, Socket}

  @impl true
  def start(_type, _args) do
    children = [
      IPSocket,
      Socket,
      InternalListener
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children ++ get_external_listeners(), opts)
  end

  defp get_external_listeners() do
    :server
    |> Application.get_env(:nat)
    |> Enum.map(fn listener ->
      name = String.to_atom(Map.get(listener, :name))

      Supervisor.child_spec(
        {ExternalListener, [nat: listener, name: name]},
        id: name
      )
    end)
  end
end
