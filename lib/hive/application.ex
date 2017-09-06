defmodule Hive.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Hive.JobServerSupervisor, [name: Hive.JobServerSupervisor]},
      {Task.Supervisor, [name: :job_supervisor]},
    ]

    opts = [strategy: :one_for_one, name: Hive.Application]
    Supervisor.start_link(children, opts)
  end
end
