defmodule Hive.Job do

  defstruct name: "echo", function: quote do: Hive.JobList.echo("Hello", "World")

  def run(%Hive.Job{name: _, function: function}) do
    try do
      {:ok, Code.eval_quoted(function)}
    rescue
      UndefinedFunctionError -> {:error, "UndefinedFunctionError"}
    end
  end

end
