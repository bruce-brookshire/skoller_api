defmodule SkollerWeb.EmailDomainView do
  use SkollerWeb, :view
  alias SkollerWeb.EmailDomainView

  def render("index.json", %{school_email_domains: school_email_domains}) do
    %{data: render_many(school_email_domains, EmailDomainView, "email_domain.json")}
  end

  def render("show.json", %{email_domain: email_domain}) do
    %{data: render_one(email_domain, EmailDomainView, "email_domain.json")}
  end

  def render("email_domain.json", %{email_domain: email_domain}) do
    %{id: email_domain.id,
      email_domain: email_domain.email_domain}
  end
end
