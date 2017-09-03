defmodule Hive.Job do
  require Logger

  defstruct( 
    name: "Hello_World",
    job_name: "echo",
    args: ["Hello", "World"],
  )

  def run(%Hive.Job{name: _, job_name: job_name, args: args}) do
    run(job_name, args)
  end

  def run(job_name, args \\ []) do
    case get_func(Hive.JobList.__info__(:functions), job_name) do
      {:found, func} -> {:ok, apply(Hive.JobList, func, args)}
      :not_found -> {:error, :not_found}
    end
  end

  def is_valid(job_name) do
    functions = Hive.JobList.__info__(:functions)
    case get_func(functions, job_name) do
      {:found, _func} -> true
      :not_found -> false
    end
  end

  defp get_func([{func, _arity} | tail], func_name) do
    if Atom.to_string(func) == func_name do
      {:found, func }
    else
      get_func(tail, func_name)
    end
  end

  defp get_func([], _func_name) do
    :not_found
  end
end
