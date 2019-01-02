defmodule Core.Org.ContactGroup do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Contact, Group, UserGroup, Workspace}
  alias Core.{Error, Repo, Validate}

  #####################
  ### API Functions ###
  #####################

  def edit_contact_group(id, %{
        tenant_id: tenant_id,
        permissions: permissions,
        workspaces: workspaces
      }) do
    query =
      case permissions do
        %{update_contact_group: 1, update_workspace: 1} ->
          from(g in Group,
            where: g.id == ^id,
            where: g.type == ^"contact",
            where: g.tenant_id == ^tenant_id
          )

        %{update_contact_group: 1} ->
          from(g in Group,
            where: g.id == ^id,
            where: g.type == ^"contact",
            where: g.tenant_id == ^tenant_id,
            where: g.workspace_id in ^workspaces
          )
      end

    query
    |> Repo.one()
    |> Validate.ecto_read(:group)
  end

  def edit_contact_group(_id, _session), do: {:error, Error.message({:user, :authorization})}

  def create_contact_group(
        %{workspace_id: workspace_id} = attrs,
        %{tenant_id: tenant_id, permissions: %{create_contact_group: 1}, type: "agent"} =
          session
      ) do
    attrs = Map.put(attrs, :tenant_id, tenant_id)
    group = %Group{id: Repo.binary_id(), type: "contact"}

    with {:ok, _workspace} <- Workspace.get_workspace(workspace_id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def create_contact_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def update_contact_group(
        %{id: id} = attrs,
        %{permissions: %{update_contact_group: 1}, type: "agent"} = session
      ) do
    attrs = Map.drop(attrs, [:workspace_id])

    with {:ok, group} <- edit_contact_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def update_contact_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def delete_contact_group(
        id,
        %{permissions: %{update_contact_group: 1}, type: "agent"} = session
      ) do
    attrs = %{}

    with {:ok, group} <- edit_contact_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.destroy(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def delete_contact_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def disable_contact_group(
        id,
        %{permissions: %{update_contact_group: 1}, type: "agent"} = session
      ) do
    attrs = %{status: "disabled"}

    with {:ok, group} <- edit_contact_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def disable_contact_group(_attrs, _session),
    do: {:error, Error.message({:user, :authorization})}

  def enable_contact_group(
        id,
        %{permissions: %{update_contact_group: 1}, type: "agent"} = session
      ) do
    attrs = %{status: "active"}

    with {:ok, group} <- edit_contact_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def enable_contact_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  ##################
  ### Changesets ###
  ##################

  def change_users_groups(
        %{data: %{id: group_id}, params: %{"users" => users} = params} = changeset,
        %{tenant_id: tenant_id, permissions: %{update_contact: 1}} = session
      ) do
    workspace_id = changeset.data.workspace_id || params["workspace_id"]

    users_groups =
      users
      |> Enum.flat_map(fn user_id ->
        case Contact.get_contact_by_workspace(user_id, workspace_id, session) do
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
  def validate_update_permissions(id, %{permissions: %{update_contact_group: 1}} = session) do
    with {:ok, group} <- edit_contact_group(id, session) do
      {:ok, group}
    else
      error ->
        error
    end
  end
end
