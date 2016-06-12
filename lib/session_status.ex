defmodule Session do
@moduledoc """
Here is defined Session structs

Please, click on source code
"""

    defmodule  Status  do
        @moduledoc false

        @doc """
        Defines the Session.Status struct
        """
        defstruct   connect_role:         :acceptor,        # :initiator
                    status:               :waitting_login,  # :login_ok, :waitting_logout
                    me_comp_id:           "ACCEPTOR",
                    other_comp_id:        "INITIATOR",
                    password:             "",
                    fix_version:          "",
                    heartbeat_interv:      0,
                    receptor_msg_seq_num:  1,
                    sender_msg_seq_num:    1
    end
end
