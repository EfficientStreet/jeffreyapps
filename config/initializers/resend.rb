# Only set when present so dev/test (which don't use the :resend delivery
# method) never require RESEND_API_KEY to boot.
Resend.api_key = ENV["RESEND_API_KEY"] if ENV["RESEND_API_KEY"].present?
