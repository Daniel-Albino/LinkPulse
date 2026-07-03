// =============================================================================
// app/javascript/controllers/index.js
// Auto-regista todos os controllers Stimulus.
// =============================================================================

import { application } from "controllers/application"

// Importa controllers individualmente ou usa eager loading:
// import HelloController from "controllers/hello_controller"
// application.register("hello", HelloController)

// Eager loading de todos os controllers (Rails 8 default):
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
