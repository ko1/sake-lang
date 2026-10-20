gem "activesupport", "8.1.3"
require "active_support"
require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/json"

# ActiveSupport::HashWithIndifferentAccess (hash_with_indifferent_access, core_ext/hash/indifferent_access)
params = { :user => { "name" => "ann", :roles => [{ id: 1 }] }, "page" => 2 }.with_indifferent_access
p(params[:page], params["page"], params[:user], params.dig(:user, :name), params.dig("user", "roles", 0, :id))
params[:sort] = "name"
p(params.keys, params.key?(:sort), params.fetch(:page), params.fetch(:missing, 0))
begin
  params.fetch(:missing)
rescue KeyError => e
  puts e.message
end
p(params.values_at(:page, "sort"), params.slice(:page, :sort), params.except(:user))
merged = params.merge(page: 3, per: 20)
p(merged[:page], merged["per"], params[:page], params.reverse_merge(page: 9, limit: 5)[:limit])
p(params.to_hash, params.except(:user).symbolize_keys)
p(params.delete(:sort), params.size, params.select { |k, v| k == "page" })
p(params == { "page" => 2, "user" => { "name" => "ann", "roles" => [{ "id" => 1 }] } }, params.slice(:page).transform_values { |v| v })
puts(ActiveSupport::JSON.encode(params))
