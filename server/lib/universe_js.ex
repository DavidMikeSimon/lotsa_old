defmodule Lotsa.UniverseJS do
  # TODO Factor out common stuff into new node_erlastic behavior

  defmodule JSError do
    defexception [:summary, :trace]

    def message(error) do
      indented = error.trace
                 |> String.split("\n")
                 |> Enum.map_join("\n", &("            #{&1}"))
      "\n#{indented}"
    end
  end

  use GenServer

  ####
  ## Client API
  ####
 
  def start(options \\ %{}) do
    GenServer.start(__MODULE__, {options}, [])
  end

  def start_link(options \\ %{}) do
    GenServer.start_link(__MODULE__, {options}, [])
  end

  def ping(pid) do
    GenServer.call(pid, {:ping, {}})
  end

  def load_config(pid, json) do
    GenServer.call(pid, {:load_config, {json}})
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  ####
  ## Server Callbacks
  ####

  def init({options}) do
    :gproc.reg({:n, :l, :universe_js}) # FIXME temporary

    js_path = Path.expand Path.join(["..", "universe_js", "server.js"])
    port = Port.open(
      {:spawn, "node #{js_path}"},
      [:binary, :exit_status, packet: 4]
    )
    send(port, {self(), {:command, :erlang.term_to_binary(options)}})
    {:ok, port}
  end

  def handle_cast(term, port) do
    send(port, {self(), {:command, :erlang.term_to_binary(term)}})
    {:noreply, port}
  end

  def handle_call(term, _reply_to, port) do
    send(port, {self(), {:command, :erlang.term_to_binary(term)}})
    response = receive do
      {^port, {:data, b}} -> :erlang.binary_to_term(b)
    end

    case response do
      {:error, {_, _, _, msg, trace}} ->
        raise JSError, summary: msg, trace: trace
      {:protobuf, :UniverseDef, bin} ->
        {:reply, Lotsa.Proto.UniverseDef.decode(bin), port}
      _ ->
        {:reply, response, port}
    end
  end

  def handle_info({port, {:exit_status,0}}, port), do: {:stop, :normal, port}
  def handle_info({port, {:exit_status,_}}, port), do: {:stop, :port_terminated, port}
  def handle_info(_, port), do: {:noreply, port}
end
