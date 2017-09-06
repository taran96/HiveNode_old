defmodule HiveTest.JobListTest do
  use ExUnit.Case

  test "echo test" do
    assert {:ok, "Hello World"} == Hive.JobList.echo("Hello", "World")
  end

  test "write to TTY" do
    tty = case Nerves.UART.enumerate |> Map.to_list do
      [{tty, _} | _tail ] -> tty
      [] -> assert false, "There are no TTY devices to test with"
    end
    assert :ok == Hive.JobList.write_to_tty(tty, "Hello")
  end

  test "write to non existing TTY" do
    assert {:error, :enoent} == Hive.JobList.write_to_tty("Doesnotexist", "Hello")
  end

  test "write to non device but existing TTY" do
    assert {:error, :einval} == Hive.JobList.write_to_tty("/dev/tty", "hello")
  end

end
