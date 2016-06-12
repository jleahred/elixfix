defmodule FProcessLogoutTest do
    use ExUnit.Case
    doctest FSessionLogoutMsg

    @init_status %Session.Status{
        connect_role:         :acceptor,
        status:               :login_ok
    }
    @init_logout_msg %{
        :MsgSeqNum => 1,
        :RefMsgType => "PR",
        :Text => "logout"
    }
    @init_expected_status %Session.Status{
        connect_role:     :acceptor,
        status:           :logout
    }
    @init_expected_status %Session.Status{
        connect_role:     :acceptor,
        status:           :logout,
    }


    test "logout on login" do
      status = @init_status
      logout = @init_logout_msg
      expected_status = @init_expected_status
      {final_status, actions} = FSessionLogoutMsg.process(status, logout)
      assert  actions == [send_message: %{Text: "received logout"}, disconnect: true]
      assert  final_status == expected_status
    end

    test "logout waitting_login" do
      status = %Session.Status{@init_status | status: :waitting_login}
      logout = @init_logout_msg
      expected_status = @init_expected_status
      {final_status, actions} = FSessionLogoutMsg.process(status, logout)
      assert  actions == [send_message: %{MsgType: "3", RefMsgType: "PR", RefSeqNum: 1,
              Text: "logout on waitting_login"}, disconnect: true]
      assert  final_status == expected_status
    end

    test "logout waitting logout" do
        status = %Session.Status{@init_status | status: :waitting_logout}
        logout = @init_logout_msg
        expected_status = @init_expected_status
        {final_status, actions} = FSessionLogoutMsg.process(status, logout)
        assert  actions == [disconnect: true]
        assert  final_status == expected_status
    end

end
