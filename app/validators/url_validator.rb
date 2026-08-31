# Validates that a value is a well-formed absolute http(s) URL.
#
# Restricting the scheme to http/https is a security control, not cosmetics:
# without it a shortener will happily store and then hand back
# "javascript:..." or "data:..." URLs, turning every short link into a
# potential XSS vector for whoever clicks it.
#
# URI.parse is used instead of a regex because URL grammar is far too
# irregular for a readable pattern to get right.
class UrlValidator < ActiveModel::EachValidator
  ALLOWED_SCHEMES = %w[http https].freeze
  DEFAULT_MESSAGE = "must be a valid http or https URL".freeze

  def validate_each(record, attribute, value)
    uri = URI.parse(value.to_s)

    unless ALLOWED_SCHEMES.include?(uri.scheme) && uri.host.present?
      record.errors.add(attribute, options[:message] || DEFAULT_MESSAGE)
    end
  rescue URI::InvalidURIError
    record.errors.add(attribute, options[:message] || DEFAULT_MESSAGE)
  end
end
