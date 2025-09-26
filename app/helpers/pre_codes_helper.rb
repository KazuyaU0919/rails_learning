# app/helpers/pre_codes_helper.rb
module PreCodesHelper
  ALLOWED_TAGS = %w[b i em strong code pre br p ul ol li a].freeze
  ALLOWED_ATTRS = %w[href].freeze

  def sanitized_html(html)
    sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
  end
end
