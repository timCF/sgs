defmodule Sgs.Macro do

	###########
	### priv ##
	###########

	defp modify_AST {a,b,c}, to_delete, to_paste do
		{modify_AST(a, to_delete, to_paste), modify_AST(b, to_delete, to_paste), modify_AST(c, to_delete, to_paste)}
	end
	defp modify_AST(lst, to_delete, to_paste) when is_list(lst) do
		Enum.map(lst, &( modify_AST(&1, to_delete, to_paste) ))
	end
	defp modify_AST to_delete, to_delete, to_paste do
		to_paste
	end
	defp modify_AST {a, b}, to_delete, to_paste do
		{modify_AST(a, to_delete, to_paste), modify_AST(b, to_delete, to_paste)}
	end
	defp modify_AST some_else, _, _ do
		some_else
	end

	############
	### public #
	############

	defmacro __using__(_) do
		quote do 
			use ExActor.GenServer
			import Sgs.Macro

			# init here
			defp init_return( {:ok, state}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state)
				end
				{:ok, name}
			end
			defp init_return( {:ok, state, some}, name ) do
				if(Exdk.get(name) == :not_found) do
					Exdk.put(name, state)
				end
				{:ok, name, some}
			end
			defp init_return( some_else, _name ) do
				some_else
			end

			# cast here
			defp cast_info_return( {:noreply, state}, name ) do
				Exdk.put(name, state)
				{:noreply, name}
			end
			defp cast_info_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state)
				{:noreply, name, some}
			end
			defp cast_info_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, state}
			end

			#call here
			defp call_return( {:reply, reply, state}, name ) do
				Exdk.put(name, state)
				{:reply, reply, name}
			end
			defp call_return( {:reply, reply, state, some}, name ) do
				Exdk.put(name, state)
				{:reply, reply, name, some}
			end
			defp call_return( {:noreply, state}, name ) do
				Exdk.put(name, state)
				{:noreply, name}
			end
			defp call_return( {:noreply, state, some}, name ) do
				Exdk.put(name, state)
				{:noreply, name, some}
			end
			defp call_return( {:stop, reason, reply, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, reply, name}
			end
			defp call_return( {:stop, reason, state}, name ) do
				Exdk.put(name, state)
				{:stop, reason, name}
			end

		end
	end

	defmacro init_sgs([do: body]) do
		res = quote do
			# notice, GS is named, name !!is atom!! 
			definit(name) do 
				:erlang.register(name, self())
				init_return( unquote(body), name )
			end
		end

		IO.puts Macro.to_string(res)

		res

	end

	defmacro cast_sgs(funcdef, [do: body]) do
		res = quote do
			defcast	unquote(funcdef), state: name do
				state = Exdk.get(name) # bound variable "state" to use it inside body of macro. Bad code, I know
				cast_info_return(unquote(body), name) # cast and info return values are the same
			end
		end |> modify_AST(Sgs.Macro, nil)

		IO.puts Macro.to_string(res)

		res

	end

	defmacro call_sgs(funcdef, [do: body]) do
		res = quote do
			defcall	unquote(funcdef), state: name do
				state = Exdk.get(name) # bound variable "state" to use it inside body of macro. Bad code, I know
				call_return(unquote(body), name)
			end
		end |> modify_AST(Sgs.Macro, nil)

		IO.puts Macro.to_string(res)

		res

	end

	defmacro info_sgs(some, [do: body]) do
		res = quote do
			definfo	unquote(some), state: name do
				state = Exdk.get(name) # bound variable "state" to use it inside body of macro. Bad code, I know
				cast_info_return(unquote(body), name) 
			end
		end |> modify_AST(Sgs.Macro, nil)

		IO.puts Macro.to_string(res)

		res

	end

end