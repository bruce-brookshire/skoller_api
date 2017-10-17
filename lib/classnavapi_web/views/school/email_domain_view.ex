defmodule ClassnavapiWeb.School.EmailDomainView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.School.EmailDomainView

  def render("index.json", %{email_domains: email_domains}) do
    render_many(email_domains, EmailDomainView, "email_domain.json")
  end

  def render("show.json", %{email_domain: email_domain}) do
    render_one(email_domain, EmailDomainView, "email_domain.json")
  end

  def render("email_domain.json", %{email_domain: email_domain}) do
    %{
      id: email_domain.id,
      email_domain: email_domain.email_domain,
      is_professor_only: email_domain.is_professor_only
    }
  end
end
