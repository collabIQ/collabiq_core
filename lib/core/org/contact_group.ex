defmodule Core.Org.ContactGroup do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Contact, Group, UserGroup, Workspace}
  alias Core.{Error, Query, Repo, UUID}

  #####################
  ### API Functions ###
  #####################

  def edit_contact_group(id, %{permissions: %{update_contact_group: 1}} = session) do
    from(g in Group, where: g.type == ^"contact")
    |> Query.edit(id, session, :group)
  end

  def create_contact_group(
        %{workspace_id: w_id} = attrs,
        %{tenant_id: t_id, permissions: %{create_contact_group: 1}, type: "agent"} =
          session
      ) do
    attrs = Map.put(attrs, :tenant_id, t_id)

    with {:ok, binary_id} <- UUID.bin_gen(),
         {:ok, change} <- Group.changeset(%Group{id: binary_id, type: "contact"}, attrs, session),
         {:ok, _workspace} <- Workspace.get_workspace(w_id, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def create_contact_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

  def update_contact_group(attrs, session) do
    Map.drop(attrs, [:workspace_id])
    |> modify_contact_group(session)
  end

  def delete_contact_group(id, session) do
    %{status: "deleted", deleted_at: Timex.now(), id: id}
    |> modify_contact_group(session)
  end

  def disable_contact_group(id, session) do
    %{status: "disabled", deleted_at: nil, id: id}
    |> modify_contact_group(session)
  end

  def enable_contact_group(id, session) do
    %{status: "active", deleted_at: nil, id: id}
    |> modify_contact_group(session)
  end

  def modify_contact_group(%{id: id} = attrs, %{permissions: %{update_contact_group: 1}, type: "agent"} = session) do
    with {:ok, group} <- edit_contact_group(id, session),
         {:ok, change} <- Group.changeset(group, attrs, session),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def modify_contact_group(_attrs, _session), do: {:error, Error.message({:user, :authorization})}

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
end
