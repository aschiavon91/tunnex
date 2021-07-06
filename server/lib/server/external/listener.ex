defmodule Server.External.Listener do
  @moduledoc false

  require Logger
  use GenServer
  alias Server.External.Worker
  alias Server.Stores.Socket
  alias Server.Utils

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(nat: nat) do
    [_, port_str] = nat |> Map.get(:from) |> String.split(":")
    port = String.to_integer(port_str)

    {:ok, acceptor} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    send(self(), :accept)
    Logger.info("Accepting connection on port #{port}")

    {:ok, %{acceptor: acceptor, nat: nat, port: port}}
  end

  def handle_info(:accept, %{acceptor: acceptor, port: port, nat: nat} = state) do
    {:ok, sock} = :gen_tcp.accept(acceptor)
    Logger.info("new connection established from port #{port}")

    sock_key = Utils.generete_socket_key()

    {:ok, pid} = GenServer.start_link(Worker, {sock, nat, sock_key})
    :gen_tcp.controlling_process(sock, pid)

    Socket.add_socket(sock_key, pid)

    send(self(), :accept)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
