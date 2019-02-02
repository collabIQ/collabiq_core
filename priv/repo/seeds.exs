# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Core.Repo.insert!(%Core.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Core.Org.{Tenant, Group, Role, User, UserGroup, UserWorkspace, Workspace}
alias Core.{Color, Repo}

{:ok, tenant} = Repo.insert(%Tenant{name: "Master Tenant"})

{:ok, ws1} =
  Repo.insert(%Workspace{
    id: Repo.binary_id(),
    tenant_id: tenant.id,
    color: Color.random(),
    name: "WS1",
    status: "active"
  })

{:ok, ws2} =
  Repo.insert(%Workspace{
    id: Repo.binary_id(),
    tenant_id: tenant.id,
    color: Color.random(),
    name: "WS2",
    status: "active"
  })

{:ok, ws3} =
  Repo.insert(%Workspace{
    id: Repo.binary_id(),
    tenant_id: tenant.id,
    color: Color.random(),
    name: "WS3",
    status: "active"
  })

{:ok, ws4} =
  Repo.insert(%Workspace{
    id: Repo.binary_id(),
    tenant_id: tenant.id,
    color: Color.random(),
    name: "WS4",
    status: "active"
  })

{:ok, ws5} =
  Repo.insert(%Workspace{
    id: Repo.binary_id(),
    tenant_id: tenant.id,
    color: Color.random(),
    name: "WS5",
    status: "active"
  })

admin_perms = %{
  create_agent: 1,
  create_agent_group: 1,
  create_article: 1,
  create_contact: 1,
  create_contact_group: 1,
  create_workspace: 1,
  update_tenant: 1,
  update_agent: 1,
  update_agent_group: 1,
  update_article: 1,
  update_contact: 1,
  update_contact_group: 1,
  update_role: 1,
  update_workspace: 1,
  create_article: 1,
  publish_article: 1,
  update_articles: 1
}

wsadmin_perms = %{
  create_agent: 1,
  create_agent_group: 1,
  create_article: 1,
  create_contact: 1,
  create_contact_group: 1,
  create_workspace: 0,
  update_tenant: 1,
  update_agent: 1,
  update_agent_group: 1,
  update_article: 1,
  update_contact: 1,
  update_contact_group: 1,
  update_role: 0,
  update_workspace: 2,
  create_article: 1,
  publish_article: 1,
  update_articles: 1
}

agent_perms = %{
  create_agent: 0,
  create_agent_group: 0,
  create_article: 1,
  create_contact: 1,
  create_contact_group: 1,
  create_workspace: 0,
  update_tenant: 0,
  update_agent: 0,
  update_agent_group: 0,
  update_article: 1,
  update_contact: 1,
  update_contact_group: 1,
  update_role: 0,
  update_workspace: 0,
  create_article: 1,
  publish_article: 0,
  update_articles: 1
}

user_perms = %{
  create_agent: 0,
  create_agent_group: 0,
  create_article: 0,
  create_contact: 0,
  create_contact_group: 0,
  create_workspace: 0,
  update_tenant: 0,
  update_agent: 0,
  update_agent_group: 0,
  update_article: 0,
  update_contact: 0,
  update_contact_group: 0,
  update_role: 0,
  update_workspace: 0
}

{:ok, admin_role} =
  Repo.insert(%Role{
    tenant_id: tenant.id,
    name: "System Administrator",
    permissions: admin_perms
  })

{:ok, wsadmin_role} =
  Repo.insert(%Role{
    tenant_id: tenant.id,
    name: "Workspace Administrator",
    permissions: wsadmin_perms
  })

{:ok, agent_role} =
  Repo.insert(%Role{tenant_id: tenant.id, name: "Agent", permissions: agent_perms})

{:ok, user_role} =
  Repo.insert(%Role{tenant_id: tenant.id, name: "User", permissions: user_perms})

{:ok, admin} =
  Repo.insert(%User{
    id: Repo.binary_id(),
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
    id: Repo.binary_id(),
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
    id: Repo.binary_id(),
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
    id: Repo.binary_id(),
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
    id: Repo.binary_id(),
    tenant_id: tenant.id,
    type: "agent",
    name: "User2",
    email: "user2@email.com",
    role_id: user_role.id,
    language: "en",
    password_hash: Comeonin.Bcrypt.hashpwsalt("password"),
    provider: "local"
  })

{:ok, ws1_network} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws1.id})
{:ok, ws1_server} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws1.id})
{:ok, ws1_desktop} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws1.id})
{:ok, ws1_sd} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws1.id})

{:ok, ws2_network} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws2.id})
{:ok, ws2_server} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws2.id})
{:ok, ws2_desktop} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws2.id})
{:ok, ws2_sd} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws2.id})

{:ok, ws3_network} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws3.id})
{:ok, ws3_server} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws3.id})
{:ok, ws3_desktop} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws3.id})
{:ok, ws3_sd} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws3.id})

{:ok, ws4_network} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws4.id})
{:ok, ws4_server} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws4.id})
{:ok, ws4_desktop} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws4.id})
{:ok, ws4_sd} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws4.id})

{:ok, ws5_network} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Network", status: "active", workspace_id: ws5.id})
{:ok, ws5_server} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Server", status: "active", workspace_id: ws5.id})
{:ok, ws5_desktop} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Desktop", status: "active", workspace_id: ws5.id})
{:ok, ws5_sd} = Repo.insert(%Group{id: Repo.binary_id(), tenant_id: tenant.id, type: "agent", name: "Service Desk", status: "active", workspace_id: ws5.id})

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
