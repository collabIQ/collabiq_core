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

  def edit_contact_group(id, %{perms: %{u_cg: 1}} = sess) do
    from(g in Group, where: g.type == ^"contact")
    |> Query.edit(id, sess, :group)
  end

  def create_contact_group(%{workspace_id: w_id} = attrs, %{t_id: t_id, perms: %{c_cg: 1}, type: "agent"} = sess) do
    attrs = Map.put(attrs, :tenant_id, t_id)

    with {:ok, binary_id} <- UUID.bin_gen(),
         {:ok, change} <- Group.changeset(%Group{id: binary_id, type: "contact"}, attrs, sess),
         {:ok, _workspace} <- Workspace.get_workspace(w_id, sess),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def create_contact_group(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  def update_contact_group(attrs, sess) do
    Map.drop(attrs, [:workspace_id])
    |> modify_contact_group(sess)
  end

  def delete_contact_group(id, sess) do
    %{status: "deleted", deleted_at: Timex.now(), id: id}
    |> modify_contact_group(sess)
  end

  def disable_contact_group(id, sess) do
    %{status: "disabled", deleted_at: nil, id: id}
    |> modify_contact_group(sess)
  end

  def enable_contact_group(id, sess) do
    %{status: "active", deleted_at: nil, id: id}
    |> modify_contact_group(sess)
  end

  def modify_contact_group(%{id: id} = attrs, %{perms: %{u_cg: 1}, type: "agent"} = sess) do
    with {:ok, group} <- edit_contact_group(id, sess),
         {:ok, change} <- Group.changeset(group, attrs, sess),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def modify_contact_group(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  ##################
  ### Changesets ###
  ##################

  def change_users_groups(
        %{data: %{id: group_id}, params: %{"users" => users} = params} = changeset,
        %{t_id: t_id, perms: %{u_c: 1}} = sess
      ) do
    workspace_id = changeset.data.workspace_id || params["workspace_id"]

    users_groups =
      users
      |> Enum.flat_map(fn user_id ->
        case Contact.get_contact_by_workspace(user_id, workspace_id, sess) do
          {:ok, _} ->
            [%UserGroup{tenant_id: t_id, group_id: group_id, user_id: user_id, workspace_id: workspace_id}]

          _ ->
            []
        end
      end)

    put_assoc(changeset, :users_groups, users_groups)
  end

  def change_users_groups(changeset, _sess), do: changeset
end
