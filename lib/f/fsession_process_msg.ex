defmodule  FSessionRecProcessMsg  do
  @moduledoc """
  Process received message, session level

  """


  import FMsgMapSupport, only: [check_tag_value: 3,
                                check_mandatory_tags: 2,
                                get_tag_value_mandatory_ints: 2]
  alias FSessionRec.Support, as: FSS

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
          * register_heart_beat: true
          * write_log: description
          * resend_msgs: {first, last}
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
          true               ->
              get_func_proc_msg(msg_map[:MsgType]).(status, msg_map)
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
          "A"   ->  &FSessionRecLogonMsg.process/2
          "5"   ->  &FSessionRecLogoutMsg.process/2
          "0"   ->  &heartbeat/2
          "1"   ->  &test_request/2
          "4"   ->  &sequence_reset/2
          "2"   ->  &resend_request/2
          "3"   ->  &session_level_reject/2
          _     ->  &not_session_message/2
      end
  end

  defp heartbeat(status, _msg_map)  do
      {status, [register_heart_beat: true]}
  end

  defp test_request(status, msg_map)  do
      {status, send_message:  %{
                :MsgType => "0",
                :TestReqID => msg_map[:TestReqID],
            }
      }
  end

  defp sequence_reset(status, msg_map)  do
      if msg_map[:GapFillFlag] == "Y" do
          if msg_map[:NewSeqNo] >= status.receptor_msg_seq_num do
              {%Session.Status{status |
                      receptor_msg_seq_num: msg_map[:NewSeqNo]},
              []}
          else
            {%Session.Status{status | status: :logout},
              [send_message: FSS.reject_msg(
                  "NewSeqNo not valid #{msg_map[:NewSeqNo]}, current seq " <>
                  " #{status.receptor_msg_seq_num}", msg_map)]
             ++ [disconnect: true]}
          end
      else
        {%Session.Status{status | status: :logout},
          [send_message: FSS.reject_msg(
              "Expected GapFillFlag==Y", msg_map)]
         ++ [disconnect: true]}
      end

  end


  defp  check_resend_seqs(begin_seq, end_seq, status)  do
      cond do
        begin_seq >= end_seq ->
                  "incorrect begin, end :  #{begin_seq}, #{end_seq}" <>
                  " begin has to be < than end"
        begin_seq < 1 ->
                  "incorrect begin :  #{begin_seq}" <>
                  " begin has to be > 0"
        begin_seq >= end_seq ->
                  "incorrect begin, end :  #{begin_seq}, #{end_seq}" <>
                  " begin has to be < than end"
        end_seq > status.sender_msg_seq_num ->
                  "incorrect end :  #{end_seq}" <>
                  " last sent #{status.sender_msg_seq_num}"
        true  ->  ""
      end
  end

  defp resend_request(status, msg_map)  do
      {[begin_seq, end_seq], errors} = get_tag_value_mandatory_ints(msg_map, [:BeginSeqNo, :EndSeqNo])
      if errors != [] do
          {status,
            [send_message: FSS.reject_msg(
                List.to_string(errors), msg_map)]}
      else
          error_desc = check_resend_seqs(begin_seq, end_seq, status)

          if error_desc == "" do
              {status, [resend_seqs: {begin_seq, end_seq}]}
          else
              {status, [send_message: FSS.reject_msg(error_desc, msg_map)]}
          end
      end

  end

  defp session_level_reject(status, msg_map)  do
    {status, [write_log: "Received session level reject #{msg_map[:MsgSeqNum]}"]}
  end

  defp not_session_message(status, _msg_map)  do
      {status, [not_session_message: true]}
  end
end
