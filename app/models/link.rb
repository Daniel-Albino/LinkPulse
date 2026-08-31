class Link < ApplicationRecord
  has_many :click_events, dependent: :destroy

  validates :url, presence: true, uniqueness: true
  validates :url, url: true, allow_blank: true

  after_create :generate_short_code

  default_scope { order(created_at: :desc) }

  def create_short_url
    protocol = Rails.application.config.force_ssl ? "https" : "http"
    "#{protocol}://#{Rails.application.routes.default_url_options[:host]}/l/#{short_code}"
  end

  private

  def generate_short_code
    characters = [("0".."9"), ("A".."Z"), ("a".."z")].flat_map(&:to_a).join
    base62 = ""
    number = id
    while number.positive?
      rest = number % 62
      base62 += characters[rest]
      number /= 62
    end
    update_column(:short_code, base62.reverse)
  end
end
