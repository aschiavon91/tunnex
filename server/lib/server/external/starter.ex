defmodule Server.External.Stater do
  @moduledoc false

  use GenServer, restart: :temporary

  alias Server.External.Supervisor, as: ExternalSupervisor

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Process.send_after(self(), :start_listeners, 100)
    {:ok, opts}
  end

  @impl true
  def handle_info(:start_listeners, state) do
    :server
    |> Application.get_env(:nat)
    |> Enum.each(&do_start_tcp_listener/1)

    {:stop, :normal, state}
  end

  defp do_start_tcp_listener(opts) do
    opts
    |> Map.to_list()
    |> ExternalSupervisor.start_tcp_listener()
  end
end
