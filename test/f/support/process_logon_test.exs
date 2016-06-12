defmodule FProcessLogonTest do
    use ExUnit.Case
    doctest FSessionLogonMsg

    @init_status %Session.Status{
        connect_role:         :acceptor,
        status:               :waitting_login,
        password:             "1234",
        heartbeat_interv:     60,
        receptor_msg_seq_num: 1,
        sender_msg_seq_num:   1
    }
    @init_logon_msg %{
        :MsgSeqNum => 1,
        :Password => "1234",
        :EncryptMethod => "0",
        :HeartBtInt => "60",
        :RefMsgType => "A",
        :ResetSeqNumFlag => "N"
    }
    @init_expected_status %Session.Status{
        connect_role:     :acceptor,
        status:           :login_ok,
        password:         "1234",
        heartbeat_interv: 60,
        receptor_msg_seq_num:  1,
        sender_msg_seq_num:    1
    }
    @init_confirm_login %{
        :EncryptMethod => "0",
        :HeartBtInt => 60,
        :MsgType => "A"
    }



    test "Process logon OK" do
        status = @init_status
        logon = @init_logon_msg
        expected_status = @init_expected_status
        confirm_login = @init_confirm_login

        {final_status, actions} = FSessionLogonMsg.process(status, logon)
        assert  actions == [send_message: confirm_login]
        assert  final_status == expected_status
    end

    test "Invalid password" do
        status = @init_status
        logon = %{@init_logon_msg | :Password => "FAKE"}
        expected_status = %Session.Status{@init_expected_status |
                                          status: :waitting_login}

        {final_status, actions} = FSessionLogonMsg.process(status, logon)
        assert  actions == [send_message: %{MsgType: "3", RefMsgType: "A", RefSeqNum: 1,
              Text: " invalid tag value on: Password(554)  "}, disconnect: true]
        assert  final_status == expected_status
    end

    test "different heart beat" do
        status = %Session.Status{@init_status | heartbeat_interv: 33}
        logon = @init_logon_msg
        expected_status = %Session.Status{@init_expected_status |
                                          status: :waitting_login,
                                          heartbeat_interv: 33}

        {final_status, actions} = FSessionLogonMsg.process(status, logon)
        assert  actions == [send_message: %{MsgType: "3", RefMsgType: "A", RefSeqNum: 1,
              Text: "Invalid HeartBtInt 60 expected 33"}, disconnect: true]
        assert  final_status == expected_status
    end

    test "wrong encrypt method" do
        status = @init_status
        logon = %{@init_logon_msg | EncryptMethod: "A"}
        expected_status = %Session.Status{@init_expected_status |
                                          status: :waitting_login}

        {final_status, actions} = FSessionLogonMsg.process(status, logon)
        assert  actions == [send_message: %{MsgType: "3", RefMsgType: "A", RefSeqNum: 1,
              Text: " invalid tag value on: EncryptMethod(98)  received: A, expected  0"},
            disconnect: true]
        assert  final_status == expected_status
    end

    test "reset seq number" do
        status = %Session.Status{@init_status |
                                      receptor_msg_seq_num: 101,
                                      sender_msg_seq_num:   314}

        logon = %{@init_logon_msg | ResetSeqNumFlag: "Y"}
        expected_status = @init_expected_status

        {final_status, actions} = FSessionLogonMsg.process(status, logon)
        assert  actions == [send_message: %{EncryptMethod: "0", HeartBtInt: 60, MsgType: "A"}]
        assert  final_status == expected_status
    end

    test "reset seq number incorrect seq number" do
        status = %Session.Status{@init_status |
                                      receptor_msg_seq_num: 101,
                                      sender_msg_seq_num:   314}

        logon = %{@init_logon_msg | ResetSeqNumFlag: "Y", MsgSeqNum: 2}
        expected_status = %Session.Status {@init_expected_status  |
                                          status:  :waitting_login,
                                          receptor_msg_seq_num: 101,
                                          sender_msg_seq_num:   314}

        {final_status, actions} = FSessionLogonMsg.process(status, logon)
        assert  actions == [send_message: %{MsgType: "3", RefMsgType: "A", RefSeqNum: 2,
              Text: "Requested reset seq but received seq_num!=1"},
            disconnect: true]
        assert  final_status == expected_status
    end


    test "logon initiator waitting_login" do
      status = %Session.Status{@init_status | connect_role: :initiator}
      logon = @init_logon_msg
      expected_status = %Session.Status{@init_expected_status |
                            connect_role: :initiator}
      #confirm_login = @init_confirm_login

      {final_status, actions} = FSessionLogonMsg.process(status, logon)
      assert  actions == []
      assert  final_status == expected_status
    end

    test "logon initiator on logout" do
      status = %Session.Status{@init_status |
                    connect_role: :initiator,
                    status: :logout}
      logon = @init_logon_msg
      expected_status = %Session.Status{@init_expected_status |
                            connect_role: :initiator,
                            status: :logout}
      #confirm_login = @init_confirm_login

      {final_status, actions} = FSessionLogonMsg.process(status, logon)
      assert  actions == [send_message: %{MsgType: "3", RefMsgType: "A", RefSeqNum: 1,
              Text: "Logon on invalid state logout"}, disconnect: true]
      assert  final_status == expected_status
    end

    test "logon initiator on waitting_logout" do
      status = %Session.Status{@init_status |
                    connect_role: :initiator,
                    status: :waitting_logout}
      logon = @init_logon_msg
      expected_status = %Session.Status{@init_expected_status |
                            connect_role: :initiator,
                            status: :logout}
      #confirm_login = @init_confirm_login

      {final_status, actions} = FSessionLogonMsg.process(status, logon)
      assert  actions == [send_message: %{MsgType: "3", RefMsgType: "A", RefSeqNum: 1,
              Text: "Logon on invalid state waitting_logout"}, disconnect: true]
      assert  final_status == expected_status
    end

end
