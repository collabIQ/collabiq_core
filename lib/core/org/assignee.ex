defmodule Core.Org.Assignee do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Query, warn: false
  alias Core.{Error, Repo, Validate}
  alias Core.Org.{Agent, AgentGroup, Assignee}

  @primary_key false
  schema "assignees" do
    field(:id, :binary_id)
    field(:tenant_id, :binary_id)
    field(:assignee_type, :string)
    field(:name, :string)
    field(:status, :string)
    field(:type, :string)
  end

  #####################
  ### API Functions ###
  #####################

  def get_assignee(id, %{tenant_id: tenant_id} = session) do
    query =
      from(a in Assignee,
        where: a.id == ^id,
        where: a.tenant_id == ^tenant_id
      )

    result =
      query
      |> Repo.one()
      |> Validate.ecto_read(:tenant)

    case result do
      {:ok, %{id: id, type: "agent", assignee_type: "user"}} ->
        Agent.get_agent(id, session)

      {:ok, %{id: id, type: "agent", assignee_type: "group"}} ->
        AgentGroup.edit_agent_group(id, session)

      error ->
        error
    end
  end

  def get_assignee(_id, _session), do: Error.message({:user, :authorization})
end
