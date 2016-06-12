defmodule  FSessionReceiverLogon.Support  do
@moduledoc false

  alias FSessionReceiver, as: FSR
  import FMsgMapSupport, only: [check_tag_value: 3,
                                get_tag_value_mandatory_int: 2,
                                check_mandatory_tags: 2]


  defp try({status, msg_map, nil}, function)  do
      function.({status, msg_map, nil})
  end

  defp try({status, msg_map, actions}, function)  do
      [first_action | _] = actions
      case  first_action do
          {:disconnect, true}     ->  {status, msg_map, actions}
          {:reject_msg, _errors}  ->  {status, msg_map, actions}
          _                       ->  function.({status, msg_map, actions})
      end
  end


  def  process_logon_on_waitlog(status, msg_map) do
      {_, errors} =
          {msg_map , []}
          |>  check_mandatory_tags([:RawData, :EncryptMethod, :HeartBtInt])
          |>  check_tag_value(:RawData, status.password)  # check password
          |>  check_tag_value(:EncryptMethod, "0")          # no encripytion

      action =  if errors == [], do: nil, else: [reject_msg: errors]

      {status, msg_map, action}
      |> try(&process_heart_beat/1)
      |> try(&process_reset_sequence/1)

  end

  @lint {~r/Refactor/, false}
  defp process_reset_sequence({status, msg_map, nil})  do
      rec_seq_num = msg_map[:MsgSeqNum]
      reset_seq_no = fn() ->
          cond   do
              rec_seq_num == status.msg_seq_num ->
                {status, msg_map, nil}
              rec_seq_num < status.msg_seq_num ->
                  {status, msg_map, [reject_msg:
                      "Invalid value on #{FTags.get_name(:MsgSeqNum)} " <>
                      "rec: #{msg_map[:MsgSeqNum]} < exp: #{status.msg_seq_num}"]}
              rec_seq_num > status.msg_seq_num ->
                  {status, msg_map, [resend_request: rec_seq_num]}
          end
      end

      case Map.get(msg_map, :ResetSeqNumFlag, nil)  do
          "N" ->  reset_seq_no.()
          nil ->  reset_seq_no.()

          "Y"   ->
                if msg_map[:MsgSeqNum] == 1  do
                    {%FSR.Status{status | msg_seq_num: 1}, msg_map, nil}
                else
                    {status, msg_map, [reject_msg:
                        "Invalid value on #{FTags.get_name(:MsgSeqNum)} " <>
                        "rec: #{msg_map[:MsgSeqNum]} != exp: 1"]}
                end

          other ->   {status, msg_map, [reject_msg:
              "Invalid value on tag #{FTags.get_name(:ResetSeqNumFlag)} rec: #{other}"]}
      end
  end

  defp process_heart_beat({status, msg_map, nil})  do
      case get_tag_value_mandatory_int(:HeartBtInt, msg_map)  do
          {:ok,    val}   ->   {%FSR.Status{status | heartbeat_interv: val}, msg_map, nil}
          {:error, desc}  ->   {status, msg_map, [reject_msg:
                            "Invalid value on tag #{FTags.get_name(:HeartBtInt)}  #{desc}"]}
      end
  end
end
