defmodule Hive.JobList do

  def echo(hello, world) do
    {:ok, "#{hello} #{world}"}
  end

  def write_to_tty(tty, string) do
    nerves_pid = start_nerves_uart()
    case Nerves.UART.open(nerves_pid, tty) do
      :ok ->
        Nerves.UART.write(nerves_pid, tty)
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

end
