defmodule Hive.Job do
  require Logger

  defstruct( 
    name: "echo",
    function: quote do: Hive.JobList.echo("Hello", "World")
  )

  def run(%Hive.Job{name: _, function: function}) do
    try do
      {:ok, Code.eval_quoted(function)}
    rescue
      UndefinedFunctionError -> {:error, "UndefinedFunctionError"}
    end
  end

  def run(job_name, args \\ []) do
    {:found, func} = get_func(Hive.JobList.__info__(:functions), job_name)
    {:ok, apply(Hive.JobList, func, args)}
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

  defp get_func([], func_name) do
    :not_found
  end
end
