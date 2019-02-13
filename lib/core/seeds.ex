defmodule Core.Seeds do
  alias Core.Org.{Tenant, Group, Role, User, UserGroup, UserWorkspace, Workspace}
  alias Core.{Color, Repo, UUID}

  def run() do
    {:ok, tenant} = Repo.insert(%Tenant{name: "Master Tenant"})

    {:ok, ws1} =
      Repo.insert(%Workspace{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        color: Color.random(),
        name: "WS1",
        status: "active"
      })

    {:ok, ws2} =
      Repo.insert(%Workspace{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        color: Color.random(),
        name: "WS2",
        status: "active"
      })

    {:ok, ws3} =
      Repo.insert(%Workspace{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        color: Color.random(),
        name: "WS3",
        status: "active"
      })

    {:ok, ws4} =
      Repo.insert(%Workspace{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        color: Color.random(),
        name: "WS4",
        status: "disabled"
      })

    {:ok, ws5} =
      Repo.insert(%Workspace{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        color: Color.random(),
        name: "WS5",
        status: "active"
      })

    admin_perms = %{
      c_ag: 1,
      c_agent: 1,
      c_art: 1,
      c_cg: 1,
      c_con: 1,
      c_tag: 1,
      c_ws: 1,
      m_role: 1,
      pub_art: 1,
      u_ag: 1,
      u_agent: 1,
      u_art: 1,
      u_cg: 1,
      u_con: 1,
      u_tag: 1,
      u_ten: 1,
      u_ws: 1
    }

    wsadmin_perms = %{
      c_ag: 1,
      c_agent: 1,
      c_art: 1,
      c_cg: 1,
      c_con: 1,
      c_tag: 1,
      c_ws: 0,
      m_role: 0,
      pub_art: 1,
      u_ag: 1,
      u_agent: 1,
      u_art: 1,
      u_cg: 1,
      u_con: 1,
      u_tag: 1,
      u_ten: 1,
      u_ws: 2
    }

    agent_perms = %{
      c_ag: 0,
      c_agent: 0,
      c_art: 1,
      c_cg: 1,
      c_con: 1,
      c_tag: 1,
      c_ws: 0,
      m_role: 0,
      pub_art: 0,
      u_ag: 0,
      u_agent: 0,
      u_art: 1,
      u_cg: 1,
      u_con: 1,
      u_tag: 1,
      u_ten: 0,
      u_ws: 0
    }

    user_perms = %{
      c_ag: 0,
      c_agent: 0,
      c_art: 0,
      c_cg: 0,
      c_con: 0,
      c_tag: 0,
      c_ws: 0,
      m_role: 0,
      pub_art: 0,
      u_ag: 0,
      u_agent: 0,
      u_art: 0,
      u_cg: 0,
      u_con: 0,
      u_tag: 0,
      u_ten: 0,
      u_ws: 0
    }

    {:ok, admin_role} =
      Repo.insert(%Role{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        name: "System Administrator",
        permissions: admin_perms,
        type: "agent"
      })

    {:ok, wsadmin_role} =
      Repo.insert(%Role{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        name: "Workspace Administrator",
        permissions: wsadmin_perms,
        type: "agent"
      })

    {:ok, agent_role} =
      Repo.insert(%Role{id: UUID.string_gen!(), tenant_id: tenant.id, name: "Agent", permissions: agent_perms, type: "agent"})

    {:ok, user_role} =
      Repo.insert(%Role{id: UUID.string_gen!(), tenant_id: tenant.id, name: "User", permissions: user_perms, type: "contact"})

    {:ok, admin} =
      Repo.insert(%User{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        type: "agent",
        name: "Admin",
        email: "admin@email.com",
        role_id: admin_role.id,
        language: "en",
        password_hash: Comeonin.Bcrypt.hashpwsalt("password"),
        provider: "local"
      })

    {:ok, wsadmin} =
      Repo.insert(%User{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        type: "agent",
        name: "WS Admin",
        email: "wsadmin@email.com",
        role_id: wsadmin_role.id,
        language: "en",
        password_hash: Comeonin.Bcrypt.hashpwsalt("password"),
        provider: "local"
      })

    {:ok, agent} =
      Repo.insert(%User{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        type: "agent",
        name: "Agent",
        email: "agent@email.com",
        role_id: agent_role.id,
        language: "en",
        password_hash: Comeonin.Bcrypt.hashpwsalt("password"),
        provider: "local"
      })

    {:ok, user1} =
      Repo.insert(%User{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        type: "agent",
        name: "User1",
        email: "user1@email.com",
        role_id: user_role.id,
        language: "en",
        password_hash: Comeonin.Bcrypt.hashpwsalt("password"),
        provider: "local"
      })

    {:ok, user2} =
      Repo.insert(%User{
        id: UUID.string_gen!(),
        tenant_id: tenant.id,
        type: "agent",
        name: "User2",
        email: "user2@email.com",
        role_id: user_role.id,
        language: "en",
        password_hash: Comeonin.Bcrypt.hashpwsalt("password"),
        provider: "local"
      })

    {:ok, ws1_network} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws1.id})
    {:ok, ws1_server} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws1.id})
    {:ok, ws1_desktop} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws1.id})
    {:ok, ws1_sd} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws1.id})

    {:ok, ws2_network} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws2.id})
    {:ok, ws2_server} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws2.id})
    {:ok, ws2_desktop} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws2.id})
    {:ok, ws2_sd} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws2.id})

    {:ok, ws3_network} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws3.id})
    {:ok, ws3_server} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws3.id})
    {:ok, ws3_desktop} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws3.id})
    {:ok, ws3_sd} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws3.id})

    {:ok, ws4_network} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws4.id})
    {:ok, ws4_server} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws4.id})
    {:ok, ws4_desktop} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws4.id})
    {:ok, ws4_sd} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws4.id})

    {:ok, ws5_network} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws5.id})
    {:ok, ws5_server} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws5.id})
    {:ok, ws5_desktop} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws5.id})
    {:ok, ws5_sd} = Repo.insert(%Group{id: UUID.string_gen!(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws5.id})

    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws1.id, user_id: admin.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws1_network.id, user_id: admin.id, workspace_id: ws1.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws1_server.id, user_id: admin.id, workspace_id: ws1.id})
    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws2.id, user_id: admin.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws2_network.id, user_id: admin.id, workspace_id: ws2.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws2_server.id, user_id: admin.id, workspace_id: ws2.id})


    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws4.id, user_id: wsadmin.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws4_server.id, user_id: wsadmin.id, workspace_id: ws4.id})
    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws5.id, user_id: wsadmin.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws5_server.id, user_id: wsadmin.id, workspace_id: ws5.id})

    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws1.id, user_id: agent.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws1_desktop.id, user_id: agent.id, workspace_id: ws1.id})
    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws4.id, user_id: agent.id})
    Repo.insert(%UserGroup{tenant_id: tenant.id, group_id: ws4_desktop.id, user_id: agent.id, workspace_id: ws4.id})

    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws3.id, user_id: user1.id})
    Repo.insert(%UserWorkspace{tenant_id: tenant.id, workspace_id: ws5.id, user_id: user2.id})
    :ok
  end
end
