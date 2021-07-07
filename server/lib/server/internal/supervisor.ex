defmodule Server.Internal.Supervisor do
  @moduledoc false

  use Supervisor

  alias Server.Internal.Tcp.Listener, as: TcpListener

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      TcpListener
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
