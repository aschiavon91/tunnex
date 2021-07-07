defmodule Server.External.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  alias Server.External.Tcp.Listener, as: TcpListener

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_tcp_listener(args) do
    DynamicSupervisor.start_child(__MODULE__, {TcpListener, args})
  end
end
