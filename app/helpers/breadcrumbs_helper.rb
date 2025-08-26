# app/helpers/breadcrumbs_helper.rb
module BreadcrumbsHelper
  def breadcrumbs_json_ld
    list = breadcrumbs.map.with_index(1) do |c, i|
      {
        "@type": "ListItem",
        position: i,
        name: c.text.to_s,
        item: (c.path ? url_for(c.path) : nil)
      }.compact
    end
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: list
    }.to_json
  end
end
