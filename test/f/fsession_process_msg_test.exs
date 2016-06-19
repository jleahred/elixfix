defmodule FSessionProcessMsgTest  do
@moduledoc false

    use ExUnit.Case
    doctest FMsgParse


    @base_status  %Session.Status{
        receptor_msg_seq_num: 0,
        fix_version:          "FIX.4.4",
        password:             "1234",
        heartbeat_interv:      60,
    }


    # checking counter in all test
    test "Process logon OK" do
        init_status = @base_status
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 1,
               status: :login_ok
        }

        logon_msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgType => "A",

            :MsgSeqNum => 1,
            :Password => "1234",
            :EncryptMethod => "0",
            :HeartBtInt => "60",
            :RefMsgType => "A",
            :ResetSeqNumFlag => "N"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, logon_msg)

        assert end_status == expected_status
        assert action == [send_message:
                      %{EncryptMethod: "0", HeartBtInt: 60, MsgType: "A"}]
    end

    test "Process message missing tags (:MsgType)" do
        init_status = @base_status
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 1
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 1
            #:MsgType => "A"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3", RefMsgType: nil,
              RefSeqNum: 1, Text: "Error missing tag MsgType(35)."}]
    end

    test "Process message missing tags (:MsgSeqNum)" do
        init_status = @base_status
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 1
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            #:MsgSeqNum => 1,
            :MsgType => "A"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3", RefMsgType: "A",
              RefSeqNum: nil,
              Text: "Error missing tag MsgSeqNum(34)."}]
    end

    test "Process message missing tags (:TargetCompID)" do
        init_status = @base_status
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 1
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            #:TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 1,
            :MsgType => "A"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3", RefMsgType: "A",
                  RefSeqNum: 1,
                  Text: "Error  invalid tag value on: TargetCompID(56)" <>
                  "  received: , expected  ACCEPTOR"}]
    end

    test "Process message missing tags (:SenderCompID)" do
        init_status = @base_status
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 1
        }

        msg = %{
            :BeginString => "FIX.4.4",
            #:SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 1,
            :MsgType => "A"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3", RefMsgType: "A",
                    RefSeqNum: 1,
                    Text: "Error  invalid tag value on: SenderCompID(49)" <>
                    "  received: , expected  INITIATOR"}]
    end

    test "Process message missing tags (:BeginString)" do
        init_status = @base_status
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 1
        }

        msg = %{
            #:BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 1,
            :MsgType => "A"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3", RefMsgType: "A",
                  RefSeqNum: 1,
                  Text: "Error  invalid tag value on: BeginString(8)" <>
                  "  received: , expected  FIX.4.4"}]
    end

    test "Process message increase sequence 1->2" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 0}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 1
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 1,
            :MsgType => "NOT_SESSION"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [not_session_message: true]
    end

    test "Process message increase sequence 101->102" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 101}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 102
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 102,
            :MsgType => "NOT_SESSION"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [not_session_message: true]
    end

    test "Process sequence bigger than expected" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 103
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 303,
            :MsgType => "NOT_SESSION"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [enqueue: true,
                send_message: %{BeginSeqNo: 103, EndSeqNo: 303, MsgType: "2"}]
    end

    test "Process sequence lower than expected" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 103
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 3,
            :MsgType => "NOT_SESSION"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3",
              RefMsgType: "NOT_SESSION", RefSeqNum: 3,
              Text: "Invalid sequence 3 expected 103"}, disconnect: true]
    end


    test "Process heartbeat" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 103
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 103,
            :MsgType => "0"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [register_heart_beat: true]
    end

    test "Process test request" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 103
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 103,
            :MsgType => "1",
            :TestReqID => "TEST-RQ-ID"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "0", TestReqID: "TEST-RQ-ID"}]
    end

    test "Process sequence reset OK" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 110
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 103,
            :MsgType => "4",
            :GapFillFlag => "Y",
            :NewSeqNo => 110
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == []
    end

    test "Process sequence reset no fill gap" do
      init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
      expected_status = %Session.Status{init_status |
             receptor_msg_seq_num: 103, status: :logout
      }

      msg = %{
          :BeginString => "FIX.4.4",
          :SenderCompID => "INITIATOR",
          :TargetCompID => "ACCEPTOR",
          :MsgSeqNum => 103,
          :MsgType => "4",
          :GapFillFlag => "N",
          :NewSeqNo => 110
      }
      {end_status, action} = FSessionProcessMsg.
                                  process_message(init_status, msg)

      assert end_status == expected_status
      assert action == [send_message: %{MsgType: "3", RefMsgType: "4",
              RefSeqNum: 103,
              Text: "Expected GapFillFlag==Y"},
              disconnect: true]
    end

    test "Process sequence reset missing fill gap" do
      init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
      expected_status = %Session.Status{init_status |
             receptor_msg_seq_num: 103, status: :logout
      }

      msg = %{
          :BeginString => "FIX.4.4",
          :SenderCompID => "INITIATOR",
          :TargetCompID => "ACCEPTOR",
          :MsgSeqNum => 103,
          :MsgType => "4",
          :NewSeqNo => 110
      }
      {end_status, action} = FSessionProcessMsg.
                                  process_message(init_status, msg)

      assert end_status == expected_status
      assert action == [send_message: %{MsgType: "3", RefMsgType: "4",
              RefSeqNum: 103,
              Text: "Expected GapFillFlag==Y"},
              disconnect: true]
    end

    test "Process sequence reset reducing sequence" do
        init_status = %Session.Status{@base_status |  receptor_msg_seq_num: 102}
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 103, status: :logout
        }

        msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 103,
            :MsgType => "4",
            :GapFillFlag => "Y",
            :NewSeqNo => 3
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3", RefMsgType: "4",
              RefSeqNum: 103,
              Text: "NewSeqNo not valid 3, current seq  103"},
              disconnect: true]
    end

    test "Process resend_request OK" do
        init_status = %Session.Status{@base_status |
               receptor_msg_seq_num: 101,
               sender_msg_seq_num: 501,
               status: :login_ok
        }
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 102
        }

        logon_msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgType => "2",
            :MsgSeqNum => 102,

            :BeginSeqNo => "400",
            :EndSeqNo => "450"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, logon_msg)

        assert end_status == expected_status
        assert action == [resend_seqs: {400, 450}]
    end

    test "Process resend_request -1 begin" do
      init_status = %Session.Status{@base_status |
             receptor_msg_seq_num: 101,
             sender_msg_seq_num: 501,
             status: :login_ok
      }
      expected_status = %Session.Status{init_status |
             receptor_msg_seq_num: 102
      }

      logon_msg = %{
          :BeginString => "FIX.4.4",
          :SenderCompID => "INITIATOR",
          :TargetCompID => "ACCEPTOR",
          :MsgType => "2",
          :MsgSeqNum => 102,

          :BeginSeqNo => "-1",
          :EndSeqNo => "450"
      }
      {end_status, action} = FSessionProcessMsg.
                                  process_message(init_status, logon_msg)

      assert end_status == expected_status
      assert action == [send_message: %{MsgType: "3", RefMsgType: "2", RefSeqNum: 102,
              Text: "incorrect begin :  -1 begin has to be > 0"}]
    end

    test "Process resend_request begin < last" do
      init_status = %Session.Status{@base_status |
             receptor_msg_seq_num: 101,
             sender_msg_seq_num: 501,
             status: :login_ok
      }
      expected_status = %Session.Status{init_status |
             receptor_msg_seq_num: 102
      }

      logon_msg = %{
          :BeginString => "FIX.4.4",
          :SenderCompID => "INITIATOR",
          :TargetCompID => "ACCEPTOR",
          :MsgType => "2",
          :MsgSeqNum => 102,

          :BeginSeqNo => "450",
          :EndSeqNo => "400"
      }
      {end_status, action} = FSessionProcessMsg.
                                  process_message(init_status, logon_msg)

      assert end_status == expected_status
      assert action == [send_message: %{MsgType: "3", RefMsgType: "2", RefSeqNum: 102,
              Text: "incorrect begin, end :  450, 400 begin has to be < than end"}]
    end

    test "Process resend_request begin == last" do
        init_status = %Session.Status{@base_status |
               receptor_msg_seq_num: 101,
               sender_msg_seq_num: 501,
               status: :login_ok
        }
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 102
        }

        logon_msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgType => "2",
            :MsgSeqNum => 102,

            :BeginSeqNo => "450",
            :EndSeqNo => "450"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, logon_msg)

        assert end_status == expected_status
        assert action == [send_message: %{MsgType: "3", RefMsgType: "2",
              RefSeqNum: 102,
              Text: "incorrect begin, end :  450, 450 begin has to be < than end"}]
    end


    test "Process resend_request last > last_sent" do
      init_status = %Session.Status{@base_status |
             receptor_msg_seq_num: 101,
             sender_msg_seq_num: 501,
             status: :login_ok
      }
      expected_status = %Session.Status{init_status |
             receptor_msg_seq_num: 102
      }

      logon_msg = %{
          :BeginString => "FIX.4.4",
          :SenderCompID => "INITIATOR",
          :TargetCompID => "ACCEPTOR",
          :MsgType => "2",
          :MsgSeqNum => 102,

          :BeginSeqNo => "450",
          :EndSeqNo => "502"
      }
      {end_status, action} = FSessionProcessMsg.
                                  process_message(init_status, logon_msg)

      assert end_status == expected_status
      assert action == [send_message: %{MsgType: "3", RefMsgType: "2", RefSeqNum: 102,
              Text: "incorrect end :  502 last sent 501"}]
    end

    test "Process session_level_reject" do
        init_status = %Session.Status{@base_status |
               receptor_msg_seq_num: 101,
               status: :login_ok
        }
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 102,
        }

        logon_msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgSeqNum => 102,
            :MsgType => "3"
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, logon_msg)

        assert end_status == expected_status
        assert action == [write_log: "Received session level reject 102"]
    end

    test "not_session_message" do
        init_status = %Session.Status{@base_status |
               receptor_msg_seq_num: 100,
               status: :login_ok
        }
        expected_status = %Session.Status{init_status |
               receptor_msg_seq_num: 101
        }

        logon_msg = %{
            :BeginString => "FIX.4.4",
            :SenderCompID => "INITIATOR",
            :TargetCompID => "ACCEPTOR",
            :MsgType => "NOT_SESSION",

            :MsgSeqNum => 101
        }
        {end_status, action} = FSessionProcessMsg.
                                    process_message(init_status, logon_msg)

        assert end_status == expected_status
        assert action == [not_session_message: true]
    end

end
