defmodule Core.Org.AgentGroup do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Agent, Group, UserGroup, Workspace}
  alias Core.{Error, Repo, Validate}

  #####################
  ### API Functions ###
  #####################
  def edit_agent_group(id, %{
        tenant_id: tenant_id,
        permissions: permissions,
        workspaces: workspaces
      }) do
    query =
      case permissions do
        %{update_agent_group: 1, update_workspace: 1} ->
          from(g in Group,
            where: g.id == ^id,
            where: g.type == ^"agent",
            where: g.tenant_id == ^tenant_id
          )

        %{update_agent_group: 1} ->
          from(g in Group,
            where: g.id == ^id,
            where: g.type == ^"agent",
            where: g.tenant_id == ^tenant_id,
            where: g.workspace_id in ^workspaces
          )
      end

    query
    |> Repo.one()
    |> Validate.ecto_read(:group)
  end

  def edit_agent_group(_id, _session), do: {:error, Error.message({:user, :authorization})}

  def create_agent_group(
        %{workspace_id: workspace_id} = attrs,
        %{tenant_id: tenant_id, permissions: %{create_agent_group: 1}, type: "agent"} = session
      ) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)
    group = %Group{id: Repo.binary_id(), type: "agent"}

    with {:ok, _workspace} <- Workspace.get_workspace(workspace_id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def create_agent_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def update_agent_group(
        %{id: id} = attrs,
        %{permissions: %{update_agent_group: p}, type: "agent"} = session
      ) when p in [1, 2] do
    attrs = Map.drop(attrs, [:workspace_id])

    with {:ok, group} <- edit_agent_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def update_agent_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def delete_agent_group(id, %{permissions: %{update_agent_group: p}, type: "agent"} = session) when p in [1, 2] do
    attrs = %{status: "deleted"}

    with {:ok, group} <- edit_agent_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def delete_agent_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def disable_agent_group(id, %{permissions: %{update_agent_group: p}, type: "agent"} = session) when p in [1, 2] do
    attrs = %{status: "disabled"}

    with {:ok, group} <- edit_agent_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def disable_agent_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def enable_agent_group(id, %{permissions: %{update_agent_group: p}, type: "agent"} = session) when p in [1, 2] do
    attrs = %{status: "active"}

    with {:ok, group} <- edit_agent_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def enable_agent_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  ##################
  ### Changesets ###
  ##################

  def change_users_groups(
        %{data: %{id: group_id}, params: %{"users" => users} = params} = changeset,
        %{tenant_id: tenant_id, permissions: %{update_agent: 1}} = session
      ) do
    workspace_id = changeset.data.workspace_id || params["workspace_id"]

    users_groups =
      users
      |> Enum.flat_map(fn user_id ->
        case Agent.get_agent_by_workspace(user_id, workspace_id, session) do
          {:ok, _} ->
            [%UserGroup{tenant_id: tenant_id, group_id: group_id, user_id: user_id, workspace_id: workspace_id}]

          _ ->
            []
        end
      end)

    put_assoc(changeset, :users_groups, users_groups)
  end

  def change_users_groups(changeset, _session), do: changeset

  ########################
  ### Helper Functions ###
  ########################
  def validate_update_permissions(id, %{permissions: %{update_agent_group: p}} = session) when p in [1, 2] do
    with {:ok, group} <- edit_agent_group(id, session) do
      {:ok, group}
    else
      error ->
        error
    end
  end
end
