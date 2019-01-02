defmodule Core.Org do
  @moduledoc """
  The Organization context. This module controls access to all Groups, Roles, Users, and Workspaces.
  """
  alias Core.Org.{Agent, AgentGroup, Contact, ContactGroup, Group, Role, Tenant, User, Workspace}

  defdelegate create_agent(attrs, session), to: Agent
  defdelegate create_agent_group(attrs, session), to: AgentGroup
  defdelegate create_contact(attrs, session), to: Contact
  defdelegate create_contact_group(attrs, session), to: ContactGroup
  defdelegate create_role(attrs, session), to: Role
  defdelegate create_workspace(attrs, session), to: Workspace

  defdelegate delete_tenant(session), to: Tenant
  defdelegate delete_agent(id, session), to: Agent
  defdelegate delete_agent_group(id, session), to: AgentGroup
  defdelegate delete_contact(id, session), to: Contact
  defdelegate delete_contact_group(id, session), to: ContactGroup
  defdelegate delete_role(id, session), to: Role
  defdelegate delete_workspace(id, session), to: Workspace

  defdelegate disable_agent(id, session), to: Agent
  defdelegate disable_agent_group(id, session), to: AgentGroup
  defdelegate disable_contact(id, session), to: Contact
  defdelegate disable_contact_group(id, session), to: ContactGroup
  defdelegate disable_workspace(id, session), to: Workspace

  defdelegate enable_tenant(session), to: Tenant
  defdelegate enable_agent(id, session), to: Agent
  defdelegate enable_agent_group(id, session), to: AgentGroup
  defdelegate enable_contact(id, session), to: Contact
  defdelegate enable_contact_group(id, session), to: ContactGroup
  defdelegate enable_workspace(id, session), to: Workspace

  defdelegate get_tenant(session), to: Tenant
  defdelegate get_agent(id, session), to: Agent
  defdelegate get_contact(id, session), to: Contact
  defdelegate get_group(id, session), to: Group
  defdelegate get_role(id, session), to: Role
  defdelegate get_user(id, session), to: User
  defdelegate get_workspace(id, session), to: Workspace

  defdelegate list_groups(args, session), to: Group
  defdelegate list_roles(session), to: Role
  defdelegate list_users(args, session), to: User
  defdelegate list_workspaces(args, session), to: Workspace

  defdelegate update_tenant(attrs, context), to: Tenant
  defdelegate update_agent(attrs, session), to: Agent
  defdelegate update_agent_group(attrs, session), to: AgentGroup
  defdelegate update_contact(attrs, session), to: Contact
  defdelegate update_contact_group(attrs, session), to: ContactGroup
  defdelegate update_role(attrs, session), to: Role
  defdelegate update_workspace(attrs, session), to: Workspace
end
