defmodule  FSessionProcessMsg  do
  @moduledoc """
  Process received message, session level

  """


  import FMsgMapSupport, only: [check_tag_value: 3, check_mandatory_tags: 2]
  alias FSession.Support, as: FSS

  @doc """
  Process message and will return action to do

  * params
      * Session.Status
      * message_map
  * returns
      * new status
      * list of actions
          * []
          * disconnect: true
          * send_message: msg
          * not_session_msg: true
          * enqueue: true
  """
  def process_message(status, msg_map) do
      status = increase_received_counter(status)
      {_, errors} = check_session_mandatory_tags(status, msg_map)
      seq_actions = check_sequence(status, msg_map)
      cond  do
          errors != []       ->   {status,
                                     [send_message: FSS.reject_msg(
                                      "Error #{errors}", msg_map)]}
          seq_actions != []  ->   {status, seq_actions}
          true               ->   get_func_proc_msg(msg_map[:MsgType]).
                                                  (status, msg_map)
      end
  end

  defp check_session_mandatory_tags(status, msg_map) do
      {msg_map, []}
      |>  check_mandatory_tags([:MsgType, :MsgSeqNum])
      |>  check_tag_value(:BeginString,  status.fix_version)
      |>  check_tag_value(:SenderCompID, status.other_comp_id)
      |>  check_tag_value(:TargetCompID, status.me_comp_id)
  end


  defp cmp(first, second) do
      cond do
          first == second  ->  :equal
          first < second   ->  :minor
          first > second   ->  :bigger
      end
  end

  defp check_sequence(status, msg_map) do
      case cmp(msg_map[:MsgSeqNum], status.receptor_msg_seq_num)  do
          :equal  ->  []
          :minor  ->  [send_message: FSS.reject_msg(
                        "Invalid sequence #{msg_map[:MsgSeqNum]} " <>
                        "expected #{status.receptor_msg_seq_num}", msg_map)]
                        ++ [disconnect: true]
          :bigger ->  [enqueue: true,
                       send_message:  request_resend(
                                            status.receptor_msg_seq_num,
                                            msg_map[:MsgSeqNum])]
      end
  end

  defp  request_resend(first, last)  do
      %{
          :MsgType =>  "2",
          :BeginSeqNo => first,
          :EndSeqNo => last
      }
  end

  defp increase_received_counter(status)  do
      %Session.Status{status |
              receptor_msg_seq_num: status.receptor_msg_seq_num + 1}
  end

  defp get_func_proc_msg(msg_type) do
      case msg_type do
          "A"   ->  &FSessionLogonMsg.process/2
          "5"   ->  &FSessionLogoutMsg.process/2
          "0"   ->  &heartbeat/2
          "1"   ->  &test_request/2
          "4"   ->  &sequence_reset/2
          "2"   ->  &resend_request/2
          "3"   ->  &session_level_reject/2
          _     ->  &not_session_message/2
      end
  end

  defp heartbeat(status, _msg_map)  do
      # TODO: anotate last received heartbeat
      {status, []}
  end

  defp test_request(status, msg_map)  do
      {status, send_message:  %{
                :MsgType => "0",
                :TestReqID => msg_map[:TestReqID],
            }
}
  end

  defp sequence_reset(_status, _msg_map)  do

  end

  defp resend_request(_status, _msg_map)  do

  end

  defp session_level_reject(_status, _msg_map)  do
    # TODO: anotate in log
  end

  defp not_session_message(status, msg_map)  do
      {status, [not_session_message: msg_map]}
  end
end
