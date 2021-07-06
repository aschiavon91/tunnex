defmodule Client.Worker do
  use GenServer
  require Logger
  alias Client.Selector
  alias Client.Stores.Socket

  def send_message(pid, message), do: GenServer.cast(pid, {:message, message})

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(socket: socket, key: key, selector: pid) do
    {:ok, %{socket: socket, key: key, selector: pid}}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.warn("worker socket closed")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _}, state) do
    Logger.error("worker socket error")
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _from, reason}, state) do
    cleanup(reason, state)
    {:stop, reason, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Logger.debug("worker recv => #{inspect(data)}")

    Selector.send_message(
      state.selector,
      <<state.key::16>> <> data
    )

    {:noreply, state}
  end

  def handle_cast({:message, message}, state) do
    Logger.debug("worker send: #{inspect(message)}")
    :ok = :gen_tcp.send(state.socket, message)
    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.warn("terminating")
    cleanup(reason, state)
    state
  end

  defp cleanup(_reason, state) do
    Socket.rm_socket(state.key)
  end
end
