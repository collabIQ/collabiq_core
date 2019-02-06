defmodule Core.Org.Contact do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{ContactGroup, User, UserGroup, UserWorkspace, Workspace}
  alias Core.{Error, Query, Repo, UUID, Validate}

  #####################
  ### API Functions ###
  #####################

  defp edit_contact(id, session) do
    from(u in User, where: u.type == ^"contact")
    |> Query.edit(id, session, :user)
  end

  def get_contact_by_workspace(id, workspace_id, %{tenant_id: tenant_id}) do
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

  def create_contact(
        attrs,
        %{tenant_id: t_id, permissions: %{create_contact: 1}, type: "agent"} = session
      ) do
    with {:ok, binary_id} <- UUID.bin_gen(),
         {:ok, change} <-
           User.changeset(%User{id: binary_id, tenant_id: t_id, type: "contact"}, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  def create_contact(_attrs, _session), do: Error.message({:user, :authorization})

  def update_contact(attrs, session) do
    attrs
    |> modify_contact(session)
  end

  def disable_contact(id, session) do
    %{status: "disabled", deleted_at: nil, id: id}
    |> modify_contact(session)
  end

  def delete_contact(id, session) do
    %{status: "deleted", deleted_at: Timex.now(), id: id}
    |> modify_contact(session)
  end

  def enable_contact(id, session) do
    %{status: "active", deleted_at: nil, id: id}
    |> modify_contact(session)
  end

  defp modify_contact(
        %{id: id} = attrs,
        %{permissions: %{update_contact: 1}, type: "agent"} = session
      ) do
    with {:ok, user} <- edit_contact(id, session),
         {:ok, change} <- User.changeset(user, attrs, session),
         {:ok, user} <- Repo.put(change) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  defp modify_contact(_attrs, _session), do: Error.message({:user, :authorization})

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

    case workspaces do
      [] ->
        changeset
        |> add_error(:user, Error.error_message(:workspace_min))

      _ ->
        users_workspaces =
          workspaces
          |> Enum.map(fn workspace_id ->
            %UserWorkspace{tenant_id: tenant_id, user_id: user_id, workspace_id: workspace_id}
          end)

        changeset
        |> put_assoc(:users_workspaces, users_workspaces)
    end
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

    workspaces =
      Enum.map(applied.users_workspaces, fn %{workspace_id: workspace_id} -> workspace_id end)

    groups = build_groups(users_groups, param_groups, user_id, workspaces, session)

    case groups do
      [] ->
        changeset

      _ ->
        changeset
        |> put_assoc(:users_groups, groups)
    end
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
      case ContactGroup.edit_contact_group(group_id, session) do
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
      case ContactGroup.edit_contact_group(group_id, session) do
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
