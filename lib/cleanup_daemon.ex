defmodule Sgs.CleanupDaemon do
	
	use ExActor.GenServer, export: :SgsCleanupDaemon

	@key :__sgs_cleanup_daemon_state__
	@timeout :timer.seconds(1)

	definit do
		case Exdk.get(@key) do
			:not_found -> {:ok, %{}, @timeout}
			state -> {:ok, cleanup(state), @timeout}
		end
	end

	defcall send_init_signal( nameproc ), state: state do

		{	:reply,
			:ok, 
			( case state[nameproc] do
				nil -> cleanup(state)
				some -> do_force_cleanup_by_reason(state, some) |> cleanup
			end ),
			@timeout 	}
	end

	defcall send_terminate_reason( reason, nameproc ), state: state do
		case HashUtils.get( state, [nameproc, :cleanup_reasons] ) |> Enum.any?( &(&1 == reason) ) do
			true -> {:reply, :ok, cleanup_process(state, nameproc), @timeout }
			false -> {:reply, :ok, HashUtils.set( state, [nameproc, :terminate_was_called], true ) |> save_state, @timeout}
		end
	end

	defcall send_terminate_reason_force( reason, nameproc ), state: state do
		case HashUtils.get( state, [nameproc, :cleanup_reasons] ) |> Enum.any?( &(&1 == reason) ) do
			true -> {:reply, :ok, cleanup_process(state, nameproc) |> force_save_state , @timeout }
			false -> {:reply, :ok, HashUtils.set( state, [nameproc, :terminate_was_called], true ) |> force_save_state, @timeout}
		end
	end

	defcall sync_send_info( input = %Sgs.SgsInfo{} ), state: state do
		{ :reply, :ok, add_info(state, input) |> cleanup, @timeout }
	end

	defcast send_info( input = %Sgs.SgsInfo{} ), state: state do
		{ :noreply, add_info(state, input) |> cleanup, @timeout }
	end

	definfo :timeout, state: state do
		{:noreply, cleanup(state), @timeout}
	end

	##############
	### priv #####
	##############

	#
	#	cleanup
	#

	defp cleanup(state) do
		Enum.reduce( Map.values(state), state, fn(val, res) -> do_cleanup_by_timestamp(res, val) |> do_cleanup_by_reason(val) end)
	end

	#
	#	cleanup by timestamp
	#

	defp do_cleanup_by_timestamp( state, %Sgs.SgsInfo{ cleanup_delay: :infinity } ) do
		# do nothing here, timestamp is not matter
		state
	end
	defp do_cleanup_by_timestamp( state, %Sgs.SgsInfo{
			nameproc: nameproc,
			timestamp: timestamp,
			cleanup_delay: cleanup_delay } ) do
		case :erlang.whereis( nameproc ) do
			# if process not alive - check delay and cleanup if need
			:undefined -> case (Exutils.makestamp - timestamp) > cleanup_delay do
							true -> cleanup_process(state, nameproc)
							false -> state
						end
			# if process alive - set new timestamp
			_ -> HashUtils.set( state, [nameproc, :timestamp], Exutils.makestamp ) |> save_state
		end
	end


	#
	#	 cleanup by reason
	#

	defp do_force_cleanup_by_reason( state,	%Sgs.SgsInfo{ 
			nameproc: nameproc,
			cleanup_reasons: cleanup_reasons, 
			terminate_was_called: false }) do

		case Enum.any?( cleanup_reasons, &(&1 == :unexpected) ) do
			true -> cleanup_process(state, nameproc)
			false -> state
		end

	end
	defp do_force_cleanup_by_reason( state,	%Sgs.SgsInfo{} ) do
		state
	end

	defp do_cleanup_by_reason( state,	%Sgs.SgsInfo{ 
				nameproc: nameproc,
				cleanup_reasons: cleanup_reasons, 
				terminate_was_called: false }) do
		case Enum.any?( cleanup_reasons, &(&1 == :unexpected) ) do
			true -> case :erlang.whereis(nameproc) do
						:undefined -> cleanup_process(state, nameproc)
						_ -> state
					end
			false -> state
		end
	end
	defp do_cleanup_by_reason( state, _ ) do
		state
	end

	##########################################
	###	work with external resources here ####
	##########################################

	defp save_state state do
		Exdk.put( @key, state)
		state
	end

	defp force_save_state state do
		Exdk.putf( @key, state)
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
		Sgs.AutoStartDaemon.delete_child(nameproc)
		new_state
	end


end