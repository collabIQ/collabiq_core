defmodule Core.Org.Agent do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{AgentGroup, User, UserGroup, UserWorkspace, Workspace}
  alias Core.{Error, Repo, Validate}

  #####################
  ### API Functions ###
  #####################
  def list_agents(args, %{
        tenant_id: tenant_id,
        permissions: permissions,
        workspaces: workspaces
      }) do
    case permissions do
      %{update_workspace: 1} ->
        from(u in User,
          where: u.tenant_id == ^tenant_id,
          where: u.type == ^"agent"
        )

      _ ->
        from(u in User,
          where: u.tenant_id == ^tenant_id,
          where: u.type == ^"agent",
          join: w in assoc(u, :workspaces),
          where: w.id in ^workspaces
        )
    end
    |> User.filter_users(args)
    |> User.sort_users(args)
    |> Repo.all()
    |> Validate.ecto_read(:users)
  end

  def list_agents(_args, _session), do: {:error, Error.message({:user, :authorization})}

  def get_agent(id, %{tenant_id: tenant_id, permissions: permissions, workspaces: workspaces}) do
    query =
      case permissions do
        %{update_workspace: 1} ->
          from(u in User,
            where: u.tenant_id == ^tenant_id,
            where: u.id == ^id,
            where: u.type == ^"agent"
          )

        _ ->
          from(u in User,
            where: u.tenant_id == ^tenant_id,
            where: u.id == ^id,
            where: u.type == ^"agent",
            join: w in assoc(u, :workspaces),
            where: w.id in ^workspaces,
            preload: [workspaces: w]
          )
      end

    query
    |> Repo.one()
    |> Validate.ecto_read(:user)
  end

  def get_agent(_id, _session), do: {:error, Error.message({:user, :authorization})}

  def get_agent_by_workspace(id, workspace_id, %{tenant_id: tenant_id}) do
    query =
      from(u in User,
        where: u.tenant_id == ^tenant_id,
        where: u.id == ^id,
        join: w in assoc(u, :workspaces),
        where: w.id == ^workspace_id
      )

    query
    |> Repo.one()
    |> Validate.ecto_read(:user)
  end

  def create_agent(
        attrs,
        %{tenant_id: tenant_id, permissions: %{create_agent: 1}, type: "agent"} = session
      ) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)
    user = %User{id: Repo.binary_id(), type: "agent"}

    with {:ok, change} <- User.changeset(user, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  def create_agent(_attrs, _session), do: Error.message({:user, :authorization})

  def update_agent(%{id: id} = attrs, %{permissions: %{update_agent: 1}, type: "agent"} = session) do
    with {:ok, user} <- get_agent(id, session),
         {:ok, change} <- User.changeset(user, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  def update_agent(_attrs, _session), do: Error.message({:user, :authorization})

  def disable_agent(id, %{permissions: %{update_agent: 1}, type: "agent"} = session) do
    attrs = %{status: "disabled"}

    with {:ok, user} <- get_agent(id, session),
         {:ok, change} <- User.changeset(user, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  def disable_agent(_id, _session), do: Error.message({:user, :authorization})

  def delete_agent(id, %{permissions: %{update_agent: 1}, type: "agent"} = session) do
    attrs = %{status: "deleted"}

    with {:ok, user} <- get_agent(id, session),
         {:ok, change} <- User.changeset(user, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  def delete_agent(_id, _session), do: Error.message({:user, :authorization})

  def enable_agent(id, %{permissions: %{update_agent: 1}, type: "agent"} = session) do
    attrs = %{status: "active"}

    with {:ok, user} <- get_agent(id, session),
         {:ok, change} <- User.changeset(user, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  def enable_agent(_id, _session), do: Error.message({:user, :authorization})

  ##################
  ### Changesets ###
  ##################

  def change_users_workspaces(
        %{
          data: %{id: user_id, users_workspaces: users_workspaces},
          params: %{"workspaces" => [_ | _] = param_workspaces}
        } = changeset,
        %{tenant_id: tenant_id, permissions: %{update_workspace: p}} = session
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
        %{permissions: %{update_contact_group: p}} = session
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
      case AgentGroup.validate_update_permissions(group_id, session) do
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
      case AgentGroup.validate_update_permissions(group_id, session) do
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
