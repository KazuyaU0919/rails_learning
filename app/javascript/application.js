// app/javascript/application.js
import "@hotwired/turbo-rails"
import "controllers"
import axios from "axios"

const token = document.querySelector('meta[name="csrf-token"]')?.content
if (token) axios.defaults.headers.common["X-CSRF-Token"] = token
