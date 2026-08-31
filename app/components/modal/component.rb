# frozen_string_literal: true

module Modal
  class Component < ViewComponent::Base

    renders_one :open_modal
    renders_one :modal_content
    renders_one :footer

    def initialize(title:, size: :default, **options)
      super()
      @title = title
      @size = size
    end

    def dialog_classes
      [
        "m-auto w-full p-0 bg-transparent backdrop:bg-black/50",
        size_classes
      ].compact.reject(&:empty?).join(" ")
    end

    private

    def size_classes
      case @size
      when :small then "max-w-sm"
      when :default then "max-w-2xl"
      when :large then "max-w-4xl"
      when :full then "max-w-[calc(100vw-2rem)]"
      end
    end

  end
end