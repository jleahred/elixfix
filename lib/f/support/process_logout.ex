defmodule  FSessionLogoutMsg  do
    @moduledoc """
    Process Logon message
    """


    @doc """
    Process logout message

    * params
        * Session.Status
        * message_map
    * returns
        * new status
        * list of actions
            * []
            * disconnect: true
            * send_message: msg
    """

    alias FSession.Support, as: FSS


    def process(status, msg_map) do
        case status.status do
            :login_ok ->
                      {%Session.Status{status | status: :logout},
                      [send_message: logout("received logout"),
                      disconnect: true]}
            :waitting_logout ->
                      {%Session.Status{status | status: :logout},
                      [disconnect: true]}
            _  ->
                      {%Session.Status{status | status: :logout},
                      [send_message: FSS.reject_msg("logout on #{status.status}",
                                                        msg_map),
                      disconnect: true]}
        end
    end


    defp logout(description) do
        %{
            :Text => description
        }
    end

end
