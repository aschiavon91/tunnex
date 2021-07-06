defmodule Server.Utils do
  @spec timestamp(atom()) :: integer
  def timestamp(type \\ :seconds), do: :os.system_time(type)

  def generete_socket_key, do: Enum.random(0..65535)
end
