defmodule Core.Org.Agent do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{AgentGroup, User, UserGroup, UserWorkspace, Workspace}
  alias Core.{Error, Query, Repo, UUID}

  #####################
  ### API Functions ###
  #####################
  defp edit_agent(id, session) do
    args = %{id: id, filter: [type: "agent"]}

    from(u in User, distinct: u.id, join: w in assoc(u, :workspaces))
    |> Query.edit(args, session, :user)
  end

  def get_agent_by_workspace(id, workspace_id, session) do
    args = %{id: id, filter: [type: "agent", workspaces: [workspace_id]]}

    from(u in User, distinct: u.id, join: w in assoc(u, :workspaces))
    |> Query.get(args, session, :user)
  end

  def create_agent(
        attrs,
        %{tenant_id: t_id, perms: %{create_agent: 1}, type: "agent"} = session
      ) do

    with {:ok, binary_id} <- UUID.string_gen(),
         {:ok, change} <- User.changeset(%User{id: binary_id, tenant_id: t_id, type: "agent"}, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  def create_agent(_attrs, _session), do: Error.message({:user, :auth})

  def update_agent(attrs, session) do
    attrs
    |> modify_agent(session)
  end

  def disable_agent(id, session) do
    %{status: "disabled", deleted_at: nil, id: id}
    |> modify_agent(session)
  end

  def delete_agent(id, session) do
    %{status: "deleted", deleted_at: Timex.now(), id: id}
    |> modify_agent(session)
  end

  def enable_agent(id, session) do
    %{status: "active", deleted_at: nil, id: id}
    |> modify_agent(session)
  end

  defp modify_agent(%{id: id} = attrs, %{perms: %{update_agent: 1}, type: "agent"} = session) do
    with {:ok, user} <- edit_agent(id, session),
         {:ok, change} <- User.changeset(user, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  defp modify_agent(_attrs, _session), do: Error.message({:user, :auth})

  ##################
  ### Changesets ###
  ##################

  def change_users_workspaces(
        %{
          data: %{id: user_id, users_workspaces: users_workspaces},
          params: %{"workspaces" => [_ | _] = param_workspaces}
        } = changeset,
        %{tenant_id: tenant_id, perms: %{update_workspace: p}} = session
      )
      when p in [1, 2] do
    workspaces = build_workspaces(users_workspaces, param_workspaces, session)

    users_workspaces =
      workspaces
      |> Enum.map(fn workspace_id ->
        %UserWorkspace{tenant_id: tenant_id, user_id: user_id, workspace_id: workspace_id}
      end)

    changeset
    |> put_assoc(:users_workspaces, users_workspaces)
  end

  def change_users_workspaces(changeset, _session), do: changeset

  defp build_workspaces([], param_workspaces, session) do
    param_workspaces(param_workspaces, session)
  end

  defp build_workspaces(users_workspaces, param_workspaces, session) do
    unaffected_workspaces = unaffected_workspaces(users_workspaces, session)
    param_workspaces = param_workspaces(param_workspaces, session)

    unaffected_workspaces ++ param_workspaces
  end

  defp unaffected_workspaces(users_workspaces, session) do
    users_workspaces
    |> Enum.map(fn %{workspace_id: workspace_id} ->
      case Workspace.validate_update_permissions(workspace_id, session) do
        {:ok, _workspace} ->
          []

        _ ->
          workspace_id
      end
    end)
    |> List.flatten()
  end

  defp param_workspaces(workspaces, session) do
    workspaces
    |> Enum.map(fn workspace_id ->
      case Workspace.validate_update_permissions(workspace_id, session) do
        {:ok, _workspace} ->
          workspace_id

        _ ->
          []
      end
    end)
    |> List.flatten()
  end

  def change_users_groups(
        %{
          data: %{id: user_id, users_groups: users_groups},
          params: %{"groups" => [_ | _] = param_groups}
        } = changeset,
        %{perms: %{u_cg: p}} = session
      )
      when p in [1, 2] do
    applied = apply_changes(changeset)

    workspaces = Enum.map(applied.users_workspaces, fn %{workspace_id: workspace_id} -> workspace_id end)

    groups = build_groups(users_groups, param_groups, user_id, workspaces, session)

    changeset
    |> put_assoc(:users_groups, groups)
  end

  def change_users_groups(changeset, _session), do: changeset

  def build_groups([], param_groups, user_id, workspaces, session) do
    param_groups(param_groups, user_id, workspaces, session)
  end

  def build_groups(users_groups, param_groups, user_id, workspaces, session) do
    unaffected_groups = unaffected_groups(users_groups, workspaces, session)
    param_groups = param_groups(param_groups, user_id, workspaces, session)

    unaffected_groups ++ param_groups
  end

  defp unaffected_groups(users_groups, workspaces, session) do
    users_groups =
      Enum.filter(users_groups, fn %{workspace_id: workspace_id} -> workspace_id in workspaces end)

    users_groups
    |> Enum.map(fn %{group_id: group_id} = group_user ->
      case AgentGroup.edit_agent_group(group_id, session) do
        {:ok, _group} ->
          []

        _ ->
          group_user
      end
    end)
    |> List.flatten()
  end

  defp param_groups(param_groups, user_id, workspaces, session) do
    param_groups
    |> Enum.map(fn group_id ->
      case AgentGroup.edit_agent_group(group_id, session) do
        {:ok, group} ->
          if group.workspace_id in workspaces do
            %UserGroup{
              tenant_id: group.tenant_id,
              group_id: group.id,
              user_id: user_id,
              workspace_id: group.workspace_id
            }
          else
            []
          end

        _ ->
          []
      end
    end)
    |> List.flatten()
  end
end
