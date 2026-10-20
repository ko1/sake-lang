# ActiveSupport::ParameterFilter: Strings, Symbols, Regexps, dotted keys, nested Hashes and Arrays, a mask.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/parameter_filter"
require "json"

params = JSON.parse('{"name": "ko1", "password": "x", "Password_confirmation": "x", "credit_card": {"number": "4242", "code": "123"},
  "tokens": [{"api_key": "k1"}, {"api_key": "k2", "label": "ci"}], "otp_attempt": 5, "ids": [1, 2]}')
f = ActiveSupport::ParameterFilter.new([:passw, "secret", /\Aapi_/, "credit_card.code", :otp])
p(f.filter(params))
p(f.filter_param("password", "x"))
p(f.filter_param("name", "ko1"))
p(ActiveSupport::ParameterFilter.new([], mask: "***").filter(params) == params)
p(ActiveSupport::ParameterFilter.new([:name, /\.number\z/], mask: "***").filter(params))
