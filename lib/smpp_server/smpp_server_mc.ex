defmodule SmppServer.MC do
  use SMPPEX.Session

  require Logger

  alias SMPPEX.Pdu
  alias SMPPEX.Pdu.Factory
  alias SMPPEX.Pdu.Errors
  alias SMPPEX.Session

  def start do
    config = Application.get_env(:smpp_server, __MODULE__)
    system_id = config[:system_id]
    port = config[:port]
    max_connections = config[:max_connections]
    Logger.info("Starting SMPPServer on port #{port}")

    {:ok, _ref} =
      SMPPEX.MC.start(
        {__MODULE__, [system_id: system_id]},
        transport_opts: [port: port, max_connections: max_connections]
      )
  end

  def init(_socket, _transport, opt) do
    {:ok,
     %{
       bound: false,
       last_msg_id: 1,
       system_id: opt[:system_id]
     }}
  end

  def handle_pdu(pdu, st) do
    case Pdu.command_name(pdu) do
      :bind_transmitter ->
        do_handle_bind(pdu, st)

      :bind_receiver ->
        do_handle_bind(pdu, st)

      :bind_transceiver ->
        do_handle_bind(pdu, st)

      :submit_sm ->
        do_handle_submit_sm(pdu, st)

      :unbind ->
        do_handle_unbind(pdu, st)

      _ ->
        {:ok, st}
    end
  end

  def handle_cast(:stop, st) do
    {:stop, :normal, st}
  end

  # Private

  defp do_handle_bind(pdu, st) do
    esme_system_id = Pdu.field(pdu, :system_id)
    Logger.info("Binding ESME with system_id: #{esme_system_id}")

    if st[:bound] do
      {:ok, [bind_resp(pdu, :ROK, st[:system_id])], st}
    else
      {:ok, [bind_resp(pdu, :ROK, st[:system_id])], %{st | bound: true}}
    end
  end

  defp bind_resp(pdu, command_status, system_id) do
    Factory.bind_resp(
      bind_resp_command_id(pdu),
      Errors.code_by_name(command_status),
      system_id
    )
    |> Pdu.as_reply_to(pdu)
  end

  defp bind_resp_command_id(pdu), do: 0x80000000 + Pdu.command_id(pdu)

  defp do_handle_submit_sm(pdu, st) do
    if st[:bound] do
      code = Errors.code_by_name(:ROK)
      msg_id = st[:last_msg_id] + 1
      resp = Factory.submit_sm_resp(code, to_string(msg_id)) |> Pdu.as_reply_to(pdu)
      {:ok, [resp], %{st | last_msg_id: msg_id}}
    else
      code = Errors.code_by_name(:RINVBNDSTS)
      resp = Factory.submit_sm_resp(code) |> Pdu.as_reply_to(pdu)
      {:ok, [resp], st}
    end
  end

  defp do_handle_unbind(pdu, st) do
    Logger.info("Unbinding ESME")

    if st[:bound] do
      resp = Factory.unbind_resp() |> Pdu.as_reply_to(pdu)
      stop()
      {:ok, [resp], st}
    else
      code = Errors.code_by_name(:RINVBNDSTS)
      resp = Factory.unbind_resp(code) |> Pdu.as_reply_to(pdu)
      {:ok, [resp], st}
    end
  end

  defp stop do
    Logger.debug("Stopping MC process #{inspect(self())}")
    Session.cast(self(), :stop)
  end
end
