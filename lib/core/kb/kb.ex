defmodule Core.Kb do
  @moduledoc """
  The Organization context. This module controls access to all Groups, Roles, Users, and Workspaces.
  """
  alias Core.Kb.{Article}

  defdelegate create_article(attrs, session), to: Article

  defdelegate get_article(id, session), to: Article

  defdelegate list_articles(args, session), to: Article
end
