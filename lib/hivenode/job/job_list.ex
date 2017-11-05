defmodule HiveNode.JobList do
  @moduledoc """
  This module contains a list of current possible jobs
  """


  @doc """
  This function prints the two arguments with a space between them.
  It is mainly for testing purposes and is required for unit tests.
  """
  def echo(hello, world) do
    {:ok, "#{hello} #{world}"}
  end


  @doc """
  This function writes to a serial device located at `tty`. It uses `Nerves.UART`
  to write to serial ports, so there is error handling on `Nerves.UART` part. The 
  `Nerves.UART` server must be running, therefore it is started at the start of the
  function

  This function has two possible returns:
  - `:ok` - The device was successfullywritten to
  - `{:error, error_msg}` - There was an error writing to the device, which is 
  represented by error_msg
  """
  def write_to_tty(tty, string) do
    nerves_pid = start_nerves_uart()
    case Nerves.UART.open(nerves_pid, tty, speed: 9600, active: false) do
      :ok ->
        Nerves.UART.write(nerves_pid,  string)
        Nerves.UART.close(nerves_pid)
      {:error, error_msg} -> {:error, error_msg}
    end
  end


  defp start_nerves_uart do
    pid = Process.whereis(Nerves.UART)
    if Process.whereis(Nerves.UART) == nil do
      {:ok, new_pid} = Nerves.UART.start_link(name: Nerves.UART)
      new_pid
    else
      pid
    end
  end

  @doc """
  This function just initializes a TCP connection and when successful it
  returns :ok. If a connection with that name already exists then it just
  returns :already_exists.
  """
  def connect_to_server(servername, host, port,
                        opts \\ [active: true, mode: :binary]) do
    case check_for_server(servername) do
      true -> :already_exists
      false ->
        {status, _} = HiveNode.TCP.Client.start_link(
          [name: servername, host: host, port: port] ++ opts
        )
        status
    end
  end

  @doc """
  This function checks if a server with the given name is already registered.
  """
  def check_for_server(servername) do
    case HiveNode.TCP.Agent.get(HiveNode.TCP.Agent, servername) do
      :notfound -> false
      _ -> true
    end
  end

  @doc """
  This function sends a message to a TCP server with the given name. It
  returns an error when the server does not exist.
  """
  def send_to_server(servername, msg) do
    case HiveNode.TCP.Agent.get(HiveNode.TCP.Agent, servername) do
      :notfound -> {:error, "Server with name #{inspect servername} does not exist"}
      pid -> HiveNode.TCP.Client.send_message(pid, msg)
    end
  end

end
