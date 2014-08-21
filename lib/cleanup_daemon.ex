defmodule Sgs.CleanupDaemon do
	
	use ExActor.GenServer, export: :SgsCleanupDaemon
	use Sgs

	@key :__sgs_cleanup_daemon_state__
	@timeout :timer.seconds(1)

	definit do
		case Exdk.get(@key) do
			:not_found -> {:ok, %{}, @timeout}
			state -> {:ok, cleanup_by_timestamp(state), @timeout}
		end
	end

	defcall send_init_signal( nameproc ), state: state do
		case state[nameproc] do
			nil -> {:reply, :ok, state, @timeout}
			someinfo -> {	:reply,
							:ok, 
							do_cleanup_in_init(state, someinfo) |> cleanup_by_timestamp,
							@timeout 	}
		end
	end

	defcall send_terminate_reason( reason, nameproc ), state: state do
		case HashUtils.get( state, [nameproc, :cleanup_reasons] ) |> Enum.any?( &(&1 == reason) ) do
			true -> {:reply, :ok, cleanup_process(state, nameproc), @timeout }
			false -> {:reply, :ok, HashUtils.set( state, [nameproc, :terminate_was_called], true ) |> save_state, @timeout}
		end
	end

	defcast send_info( input = %Sgs.SgsInfo{} ), state: state do
		{ :noreply, add_info(state, input) |> cleanup_by_timestamp, @timeout }
	end

	definfo :timeout, state: state do
		{:noreply, cleanup_by_timestamp(state), @timeout}
	end

	##############
	### priv #####
	##############

	#
	#	cleanup by timestamp
	#

	defp cleanup_by_timestamp( state ) do
		Enum.reduce( Map.values(state), state, fn(val, res) -> do_cleanup_by_timestamp(res, val) end)
	end
	defp do_cleanup_by_timestamp( state, %Sgs.SgsInfo{ cleanup_delay: :infinity } )do
		# do nothing here, timestamp is not matter
		state
	end
	defp do_cleanup_by_timestamp( state, %Sgs.SgsInfo{
			nameproc: nameproc,
			timestamp: timestamp,
			cleanup_delay: cleanup_delay } ) do
		case :erlang.whereis( nameproc ) do
			# if process not alive - check delay and cleanup if need
			:undefined -> case (makestamp - timestamp) > cleanup_delay do
							true -> cleanup_process(state, nameproc)
							false -> state
						end
			# if process alive - set new timestamp
			_ -> HashUtils.set( state, [nameproc, :timestamp], makestamp ) |> save_state
		end
	end


	#
	#	cleanup in init
	#

	defp do_cleanup_in_init( state,	%Sgs.SgsInfo{ 
				nameproc: nameproc,
				cleanup_reasons: cleanup_reasons, 
				terminate_was_called: false }) do
		case Enum.any?( cleanup_reasons, &(&1 == :unexpected) ) do
			true -> cleanup_process(state, nameproc)
			false -> state
		end
	end
	defp do_cleanup_in_init( state, _ ) do
		state
	end

	##########################################
	###	work with external resources here ####
	##########################################

	defp save_state state do
		Exdk.put(state)
		state
	end

	defp add_info(state, input = %Sgs.SgsInfo{nameproc: nameproc}) do
		new_state = HashUtils.add(state, nameproc ,input)
		Exdk.put( @key, new_state )
		new_state
	end

	defp cleanup_process state, nameproc do
		Exdk.delete( nameproc )
		new_state = HashUtils.delete(state, nameproc)
		Exdk.put( @key, new_state )
		new_state
	end


end