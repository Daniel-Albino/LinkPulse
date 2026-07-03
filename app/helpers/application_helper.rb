# =============================================================================
# app/helpers/application_helper.rb
# Global helpers available in all views.
# =============================================================================

module ApplicationHelper
  # Dynamic page title
  # Usage in view: content_for :title, "Articles Page"
  # No layout: <%= page_title %>
  def page_title(separator: " | ")
    base = "LinkPulse"
    return base unless content_for?(:title)

    "#{content_for(:title)}#{separator}#{base}"
  end

  # Conditional CSS classes for flash messages
  def flash_class(type)
    {
      "notice" => "flash flash--notice",
      "success" => "flash flash--success",
      "alert" => "flash flash--alert",
      "error" => "flash flash--error",
      "warning" => "flash flash--warning"
    }.fetch(type.to_s, "flash flash--notice")
  end

  # Consistent date formatting
  def format_date(date, format: :long)
    return "" if date.blank?

    l(date.to_date, format: format)
  end

  def format_datetime(datetime, format: :long)
    return "" if datetime.blank?

    l(datetime, format: format)
  end

  # Render inline SVG icon (if using an icon library)
  # def icon(name, **options)
  #   content_tag :span, class: "icon icon--#{name}", **options do
  #     render "shared/icons/#{name}"
  #   end
  # end
end
