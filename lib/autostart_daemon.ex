defmodule Sgs.AutoStartDaemon do

	#
	#	state here - map of childs, key is atom, val is function/0
	#


	use ExActor.GenServer, export: :SgsAutoStartDaemon
	require Logger

	@key :__sgs_autostart_daemon_state__

	defmodule StarterState do
		@derive [HashUtils]
		defstruct pglist: [:__default_pg__], childs: %{}
	end
	defmodule Child do
		@derive [HashUtils]
		defstruct module: nil, pg: :__default_pg__ 
	end

	definit do
		case Exdk.get(@key) do
			:not_found -> {:ok, %StarterState{}}
			state -> {:ok, state}
		end
	end

	defcall start_childs, state: state = %StarterState{pglist: pglist, childs: childs} do
		res = Enum.map( pglist, 
				fn(pgname) -> 
					HashUtils.filter_v(childs, &( &1.pg == pgname ))
						|> HashUtils.keys
							|> Enum.map( fn(key) -> ExTask.run( fn() -> HashUtils.get(childs, [key, :module]).__autostart_func__(key) end ) end )
								|> Enum.map ( &({:result, {:ok, _}} = ExTask.await(&1)) )
				end ) |> List.flatten
		if( length(res) != length(HashUtils.keys(state, [:childs])) ) do
			Logger.warn "Sgs.AutoStartDaemon : warning! Not all childs were started!"
		end
		{:reply, :ok, state}
	end
	defcall start_childs(pglist), state: state = %StarterState{childs: childs} do
		res = Enum.map( pglist, 
				fn(pgname) -> 
					HashUtils.filter_v(childs, &( &1.pg == pgname ))
						|> HashUtils.keys
							|> Enum.map( fn(key) -> ExTask.run( fn() -> HashUtils.get(childs, [key, :module]).__autostart_func__(key) end ) end )
								|> Enum.map ( &( {:result, {:ok, _}} = ExTask.await(&1)) )
				end ) |> List.flatten
		{:reply, :ok, state}
	end

	defcall set_pglist(lst), when: is_list(lst), state: state do
		res =	case Enum.member?(lst, :__default_pg__) do
					true -> lst
					false -> lst++[:__default_pg__]
				end
		{:reply, :ok, HashUtils.set(state, :pglist, res) |> save_state}
	end

	defcall add_child(nameproc, module), state: state do
		{:reply, :ok, HashUtils.add(state, [:childs, nameproc], %Child{module: module}) |> save_state}
	end
	defcall add_child(nameproc, module, pg), state: state do
		{:reply, :ok, HashUtils.add(state, [:childs, nameproc], %Child{module: module, pg: pg}) |> save_state}
	end

	defcall delete_child(nameproc), state: state do
		{:reply, :ok, HashUtils.delete(state, [:childs, nameproc]) |> save_state}
	end

	defp save_state(state) do
		Exdk.put(@key, state)
		state
	end

end