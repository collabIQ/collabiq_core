defmodule Core.Org.AgentGroup do
  @moduledoc false
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Core.Org.{Agent, Group, UserGroup, Workspace}
  alias Core.{Error, Query, Repo, UUID}

  #####################
  ### API Functions ###
  #####################
  def edit_agent_group(id, %{perms: %{u_ag: 1}, t_id: t_id} = sess) do
    args = %{filter: [type: "agent"]}

    from(g in Group,
      where: g.tenant_id == ^t_id,
      where: g.id == ^id
    )
    |> Query.workspace_scope(sess, :group)
    |> Query.filter(args, :group)
    |> Repo.single()
    |> Repo.validate_read(:group)
  end

  def edit_agent_group(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  def create_agent_group(%{workspace_id: w_id} = attrs, %{t_id: t_id, perms: %{c_ag: 1}} = sess) do
    with {:ok, id} <- UUID.string_gen(),
         {:ok, change} <-
           Group.changeset(
             %Group{id: id, tenant_id: t_id, type: "agent", workspace_id: w_id},
             attrs,
             sess
           ),
         {:ok, _ws} <- Workspace.get_workspace(w_id, sess),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def create_agent_group(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  def update_agent_group(attrs, sess) do
    modify_agent_group(attrs, sess)
  end

  def delete_agent_group(%{id: id}, sess) do
    %{status: "deleted", deleted_at: Timex.now(), id: id}
    |> modify_agent_group(sess)
  end

  def disable_agent_group(%{id: id}, sess) do
    %{status: "disabled", deleted_at: nil, id: id}
    |> modify_agent_group(sess)
  end

  def enable_agent_group(%{id: id}, sess) do
    %{status: "active", deleted_at: nil, id: id}
    |> modify_agent_group(sess)
  end

  def modify_agent_group(%{id: id} = attrs, %{perms: %{u_ag: 1}, type: "agent"} = sess) do
    with {:ok, group} <- edit_agent_group(id, sess),
         {:ok, change} <- Group.changeset(group, attrs, sess),
         {:ok, group} <- Repo.put(change) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  def modify_agent_group(_attrs, _sess), do: {:error, Error.message({:user, :auth})}

  ##################
  ### Changesets ###
  ##################

  def change_users_groups(
        %{
          data: %{id: group_id, tenant_id: t_id, workspace_id: ws_id},
          params: %{"users" => users}
        } = change,
        %{perms: %{u_agent: 1}} = sess
      ) do
    users_groups =
      users
      |> Enum.flat_map(fn user_id ->
        case Agent.edit_agent_by_workspace(user_id, ws_id, sess) do
          {:ok, _} ->
            [
              %UserGroup{
                tenant_id: t_id,
                group_id: group_id,
                user_id: user_id,
                workspace_id: ws_id
              }
            ]

          _ ->
            []
        end
      end)

    put_assoc(change, :users_groups, users_groups)
  end

  def change_users_groups(change, _sess), do: change
end
