defmodule Core.Error do
  @moduledoc false
  import Core.Gettext

  defp changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&format_error/1)
    |> Enum.map(fn {key, value} ->
      %{message: to_string(key) <> " " <> to_string(value)}
    end)
  end

  defp format_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  def error_key(key) do
    case key do
      :account -> dgettext("errors", "account")
      :accounts -> dgettext("errors", "accounts")
      :article -> dgettext("errors", "article")
      :articles -> dgettext("errors", "articles")
      :assignee -> dgettext("errors", "assignee")
      :assignees -> dgettext("errors", "assignees")
      :agent -> dgettext("errors", "agent")
      :agents -> dgettext("errors", "agents")
      :agent_group -> dgettext("errors", "agent group")
      :agent_groups -> dgettext("errors", "agent groups")
      :contact -> dgettext("errors", "contact")
      :contacts -> dgettext("errors", "contacts")
      :group -> dgettext("errors", "group")
      :groups -> dgettext("errors", "groups")
      :login -> dgettext("errors", "login")
      :role -> dgettext("errors", "role")
      :roles -> dgettext("errors", "roles")
      :session -> dgettext("errors", "session")
      :tenant -> dgettext("errors", "tenant")
      :tenants -> dgettext("errors", "tenants")
      :token -> dgettext("errors", "token")
      :user -> dgettext("errors", "user")
      :users -> dgettext("errors", "users")
      :workspace -> dgettext("errors", "workspace")
      :workspaces -> dgettext("errors", "workspaces")
      _ -> dgettext("errors", "oops")
    end
  end

  def error_message(message) do
    case message do
      :authorization -> dgettext("errors", "not authorized")
      :create -> dgettext("errors", "could not be created")
      :delete -> dgettext("errors", "could not be deleted")
      :disable -> dgettext("errors", "could not be disabled")
      :incorrect -> dgettext("errors", "is incorrect")
      :invalid -> dgettext("errors", "is invalid")
      :not_found -> dgettext("errors", "not found")
      :role_users -> dgettext("errors", "is assigned to at least 1 user")
      :update -> dgettext("errors", "could not be updated")
      :user_workspaces_min -> dgettext("errors", "must belong to at least 1 workspace")
      :workspace_min -> dgettext("errors", "must belong to at least 1 workspace")
      _ -> dgettext("errors", "something went wrong")
    end
  end

  def message(%Ecto.Changeset{} = changeset) do
    changeset
    |> changeset_errors()
  end

  def message({key, message}) when is_atom(key) and is_atom(message) do
    [%{message: error_key(key) <> " " <> error_message(message)}]
    # [%{key: error_key(key), message: error_message(message)}]
  end

  def message(_) do
    [%{message: error_key(nil) <> " " <> error_message(nil)}]
    # [%{key: error_key(nil), message: error_message(nil)}]
  end
end
