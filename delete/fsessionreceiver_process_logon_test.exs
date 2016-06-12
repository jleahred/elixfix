defmodule FSessionReceiverSupportProcessLogon_test do
  use ExUnit.Case
  import FSessionReceiverLogon.Support

  test "process_logon_on_waitlog OK" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       1
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 1,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
            nil}
  end

  test "process_logon_on_waitlog missing mandatory tags (pass)" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       1
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡98=0‡108=30‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 1,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
          [reject_msg:
               ["missing tag RawData(96).",
                " invalid tag value on: RawData(96)  "]]}
  end


  test "process_logon_on_waitlog missing mandatory tag heartbeat_interv" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       1
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡96=PASS1234‡98=0‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 1,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
          [reject_msg: ["missing tag HeartBtInt(108)."]]}
  end

  test "process_logon_on_waitlog invalid password" do
    status0 = %FSessionReceiver.Status{
          state:            :waitting_login,   # :login_ok
          fix_version:      "FIX.4.4",
          sender_comp_id:   "SEND_TEST",
          target_comp_id:   "TARGET_TEST",
          password:         "PASS1234___FAKE",
          heartbeat_interv:  30,
          msg_seq_num:       1
    }
    msg_map = FMsgParse.parse_string_test(
        "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
        "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡10=143‡", "‡").parsed.msg_map

    {status, _, action} = process_logon_on_waitlog(status0, msg_map)
    assert {status, action}  ==
        {%FSessionReceiver.Status{
              fix_version: "FIX.4.4",
              heartbeat_interv: 30,
              msg_seq_num: 1,
              password: "PASS1234___FAKE",
              sender_comp_id: "SEND_TEST",
              state: :waitting_login,
              target_comp_id: "TARGET_TEST"},
          [reject_msg: [" invalid tag value on: RawData(96)  "]]}
  end

  test "process_logon_on_waitlog invalid encrypt method" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       1
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡96=PASS1234‡98=1‡108=30‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 1,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
          [reject_msg:
           [" invalid tag value on: EncryptMethod(98)  received: 1, expected  0"]]}
  end

  test "process_logon_on_waitlog. process_heart_beat. OK" do
    status0 = %FSessionReceiver.Status{
          state:            :waitting_login,   # :login_ok
          fix_version:      "FIX.4.4",
          sender_comp_id:   "SEND_TEST",
          target_comp_id:   "TARGET_TEST",
          password:         "PASS1234",
          heartbeat_interv:  30,
          msg_seq_num:       1
    }
    msg_map = FMsgParse.parse_string_test(
        "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
        "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡10=143‡", "‡").parsed.msg_map

    {status, _, action} = process_logon_on_waitlog(status0, msg_map)
    assert {status, action}  ==
        {%FSessionReceiver.Status{
              fix_version: "FIX.4.4",
              heartbeat_interv: 30,
              msg_seq_num: 1,
              password: "PASS1234",
              sender_comp_id: "SEND_TEST",
              state: :waitting_login,
              target_comp_id: "TARGET_TEST"},
        nil}
  end


  test "process_logon_on_waitlog. process_heart_beat. OK, modif" do
    status0 = %FSessionReceiver.Status{
          state:            :waitting_login,   # :login_ok
          fix_version:      "FIX.4.4",
          sender_comp_id:   "SEND_TEST",
          target_comp_id:   "TARGET_TEST",
          password:         "PASS1234",
          heartbeat_interv:  60,
          msg_seq_num:       1
    }
    msg_map = FMsgParse.parse_string_test(
        "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
        "56=TT_ORDER‡96=PASS1234‡98=0‡108=35‡10=143‡", "‡").parsed.msg_map

    {status, _, action} = process_logon_on_waitlog(status0, msg_map)
    assert {status, action}  ==
        {%FSessionReceiver.Status{
              fix_version: "FIX.4.4",
              heartbeat_interv: 35,
              msg_seq_num: 1,
              password: "PASS1234",
              sender_comp_id: "SEND_TEST",
              state: :waitting_login,
              target_comp_id: "TARGET_TEST"},
        nil}
  end


  test "process_logon_on_waitlog. process_heart_beat. invalid int" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       1
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡96=PASS1234‡98=0‡108=AAAA‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 1,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
          [reject_msg:
             "Invalid value on tag HeartBtInt(108)  invalid val on tag HeartBtInt(108)"]}
  end


  test "process_logon_on_waitlog. reset seq. no. seq == expected" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       102
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=102‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 102,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
            nil}
  end

  test "process_logon_on_waitlog. reset seq. no. seq > expected" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       101
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=102‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 101,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
          [resend_request: 102]}
  end

  test "process_logon_on_waitlog. reset seq. no. seq < expected" do
      status0 = %FSessionReceiver.Status{
            state:            :waitting_login,   # :login_ok
            fix_version:      "FIX.4.4",
            sender_comp_id:   "SEND_TEST",
            target_comp_id:   "TARGET_TEST",
            password:         "PASS1234",
            heartbeat_interv:  30,
            msg_seq_num:       107
      }
      msg_map = FMsgParse.parse_string_test(
          "8=FIX.4.2‡9=71‡35=A‡34=102‡49=REMOTE‡52=20120330-19:23:32‡" <>
          "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡10=143‡", "‡").parsed.msg_map

      {status, _, action} = process_logon_on_waitlog(status0, msg_map)
      assert {status, action}  ==
          {%FSessionReceiver.Status{
                fix_version: "FIX.4.4",
                heartbeat_interv: 30,
                msg_seq_num: 107,
                password: "PASS1234",
                sender_comp_id: "SEND_TEST",
                state: :waitting_login,
                target_comp_id: "TARGET_TEST"},
          [reject_msg: "Invalid value on MsgSeqNum(34) rec: 102 < exp: 107"]}
  end

  test "process_logon_on_waitlog. reset seq. NO OK" do
    status0 = %FSessionReceiver.Status{
          state:            :waitting_login,   # :login_ok
          fix_version:      "FIX.4.4",
          sender_comp_id:   "SEND_TEST",
          target_comp_id:   "TARGET_TEST",
          password:         "PASS1234",
          heartbeat_interv:  30,
          msg_seq_num:       107
    }
    msg_map = FMsgParse.parse_string_test(
        "8=FIX.4.2‡9=71‡35=A‡34=107‡49=REMOTE‡52=20120330-19:23:32‡" <>
        "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡141=N‡10=143‡", "‡").parsed.msg_map

    {status, _, action} = process_logon_on_waitlog(status0, msg_map)
    assert {status, action}  ==
        {%FSessionReceiver.Status{
              fix_version: "FIX.4.4",
              heartbeat_interv: 30,
              msg_seq_num: 107,
              password: "PASS1234",
              sender_comp_id: "SEND_TEST",
              state: :waitting_login,
              target_comp_id: "TARGET_TEST"},
        nil}
  end

  test "process_logon_on_waitlog. reset seq. yes. 1 OK" do
    status0 = %FSessionReceiver.Status{
          state:            :waitting_login,   # :login_ok
          fix_version:      "FIX.4.4",
          sender_comp_id:   "SEND_TEST",
          target_comp_id:   "TARGET_TEST",
          password:         "PASS1234",
          heartbeat_interv:  30,
          msg_seq_num:       107
    }
    msg_map = FMsgParse.parse_string_test(
        "8=FIX.4.2‡9=71‡35=A‡34=1‡49=REMOTE‡52=20120330-19:23:32‡" <>
        "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡141=Y‡10=143‡", "‡").parsed.msg_map

    {status, _, action} = process_logon_on_waitlog(status0, msg_map)
    assert {status, action}  ==
        {%FSessionReceiver.Status{
              fix_version: "FIX.4.4",
              heartbeat_interv: 30,
              msg_seq_num: 1,
              password: "PASS1234",
              sender_comp_id: "SEND_TEST",
              state: :waitting_login,
              target_comp_id: "TARGET_TEST"},
        nil}
  end

  test "process_logon_on_waitlog. reset seq. yes. !=1  wrong" do
    status0 = %FSessionReceiver.Status{
          state:            :waitting_login,   # :login_ok
          fix_version:      "FIX.4.4",
          sender_comp_id:   "SEND_TEST",
          target_comp_id:   "TARGET_TEST",
          password:         "PASS1234",
          heartbeat_interv:  30,
          msg_seq_num:       107
    }
    msg_map = FMsgParse.parse_string_test(
        "8=FIX.4.2‡9=71‡35=A‡34=107‡49=REMOTE‡52=20120330-19:23:32‡" <>
        "56=TT_ORDER‡96=PASS1234‡98=0‡108=30‡141=Y‡10=143‡", "‡").parsed.msg_map

    {status, _, action} = process_logon_on_waitlog(status0, msg_map)
    assert {status, action}  ==
        {%FSessionReceiver.Status{
              fix_version: "FIX.4.4",
              heartbeat_interv: 30,
              msg_seq_num: 107,
              password: "PASS1234",
              sender_comp_id: "SEND_TEST",
              state: :waitting_login,
              target_comp_id: "TARGET_TEST"},
        [reject_msg: "Invalid value on MsgSeqNum(34) rec: 107 != exp: 1"]}
  end

end
