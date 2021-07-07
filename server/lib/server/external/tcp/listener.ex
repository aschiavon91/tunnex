defmodule Server.External.Tcp.Listener do
  @moduledoc false

  use GenServer

  alias Server.External.Tcp.Worker
  alias Server.External.SocketStore
  alias Server.Utils

  require Logger

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    name = String.to_atom("#{__MODULE__}/#{name}")
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(from: from, to: to) do
    [_, port_str] = String.split(from, ":")
    port = String.to_integer(port_str)

    {:ok, acceptor} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    send(self(), :accept)
    Logger.info("#{__MODULE__} accepting connection on port #{port}")

    {:ok, %{acceptor: acceptor, to: to, port: port}}
  end

  @impl true
  def handle_info(:accept, %{acceptor: acceptor, port: port, to: to} = state) do
    {:ok, sock} = :gen_tcp.accept(acceptor)
    Logger.info("#{__MODULE__} new connection established from port #{port}")

    sock_key = Utils.generete_socket_key()

    {:ok, pid} = GenServer.start_link(Worker, {sock, to, sock_key})
    :gen_tcp.controlling_process(sock, pid)

    SocketStore.add_socket(sock_key, pid)

    send(self(), :accept)
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
