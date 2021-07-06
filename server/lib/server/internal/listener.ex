defmodule Server.Internal.Listener do
  require Logger

  use GenServer

  alias Server.Internal.Worker

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], name:  Keyword.get(opts, :name))
  end

  def init(_opts) do
    port = server_port()
    {:ok, acceptor} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true, packet: 2])
    send(self(), :accept)

    Logger.info("Accepting connection on port #{port}")
    {:ok, %{acceptor: acceptor}}
  end

  def handle_info(:accept, %{acceptor: acceptor} = state) do
    {:ok, sock} = :gen_tcp.accept(acceptor)

    {:ok, pid} = GenServer.start_link(Worker, socket: sock)

    :gen_tcp.controlling_process(sock, pid)

    send(self(), :accept)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp server_port, do: Application.get_env(:server, :port)
end
