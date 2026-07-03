# =============================================================================
# config/importmap.rb
# Mapeamento de pacotes JavaScript via importmap (sem bundler).
# =============================================================================

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
