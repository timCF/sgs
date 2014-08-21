defmodule Sgs do
  use Application

  defmacro __using__(_) do
    quote do
      defp makestamp do
        {a, b, c} = :os.timestamp
        a*1000000000 + b*1000 + round( c / 1000)
      end
    end
  end

  # some info about each SGS, helps CleanupDaemon do his work
  defmodule SgsInfo do
    @derive [HashUtils]
    defstruct nameproc: nil, # name of SGS (it always named)
              timestamp: 0, # timestamp of last using
              cleanup_delay: :infinity, # cleanup state when (current_time - timestamp > cleanup_delay) AND (process is not alive). If cleanup_delay == :infinity, never cleanup by timeout.
              cleanup_reasons: [ :normal ], # cleanup state of SGS immediately if it terminating with some of these reasons. ALSO here can be :unexpected - it calls cleanup if terminate function was not called when SGS falls.
              terminate_was_called: false # set true in terminate function, set false in init function
  end


  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [  worker(Sgs.CleanupDaemon, []) , worker(CompileTest, [:myself])
      # Define workers and child supervisors to be supervised
      # worker(Sgs.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sgs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
