gem "actionview", "8.1.3"
gem "activemodel", "8.1.3"
require "action_view"
require "active_model"
require "active_support/core_ext/date"

# Records for the collection helpers
class Person
  include ActiveModel::Model
  attr_accessor :id, :name, :city_id
  def persisted? = true
end
class Continent
  include ActiveModel::Model
  attr_accessor :name, :countries
end

view = ActionView::Base.empty
people = [Person.new(id: 1, name: "David", city_id: 2), Person.new(id: 2, name: "Sam <b>", city_id: 1), Person.new(id: 3, name: "Tobias", city_id: 2)]
person = Person.new(id: 4, name: "Ann", city_id: 2)

# options_for_select
puts view.options_for_select(["VISA", "MasterCard"])
puts view.options_for_select([["Dollar", "$"], ["Kroner", "DKK"]])
puts view.options_for_select([["Dollar", "$"], ["Kroner", "DKK"]], "$")
puts view.options_for_select(["VISA", "MasterCard", "Discover"], ["VISA", "Discover"])
puts view.options_for_select({ "Basic" => "$20", "Plus" => "$40" }, "$40")
puts view.options_for_select([["Lisbon", 1, { data: { size: "2.8 million" } }], ["Madrid", 2, { class: "big" }]], 2)
puts view.options_for_select(["Free", "Basic", "Advanced", "Super Platinum"], disabled: "Super Platinum")
puts view.options_for_select(["Free", "Basic", "Advanced"], selected: "Free", disabled: ["Basic", "Advanced"])
puts view.options_for_select(1..3, 2)
puts view.options_for_select(["<a>", "b&c"])
puts view.options_for_select("<option>raw</option>".html_safe)
# collections
puts view.options_from_collection_for_select(people, "id", "name")
puts view.options_from_collection_for_select(people, :id, :name, 3)
puts view.options_from_collection_for_select(people, :id, :name, [1, 3])
puts view.options_from_collection_for_select(people, :id, :name, selected: 1, disabled: 2)
continents = [Continent.new(name: "Africa", countries: [Person.new(id: 5, name: "Egypt"), Person.new(id: 6, name: "Rwanda")]), Continent.new(name: "Europe", countries: [Person.new(id: 7, name: "Denmark")])]
puts view.option_groups_from_collection_for_select(continents, :countries, :name, :id, :name, 6)
puts view.grouped_options_for_select({ "North America" => [["United States", "US"], "Canada"], "Europe" => ["Denmark", "Germany"] }, "Canada")
puts view.grouped_options_for_select([["North America", ["US", "Canada"]], ["Europe", ["Denmark"]]], nil, prompt: "Choose")
puts view.grouped_options_for_select([["US", "Canada"], ["Denmark", "Germany"]], nil, divider: "---------")
puts view.weekday_options_for_select
puts view.weekday_options_for_select("Friday", day_format: :abbr_day_names)
puts view.weekday_options_for_select(2, index_as_value: true, beginning_of_week: :sunday)
# select and friends on an object
puts view.select(:person, :city_id, [["Paris", 1], ["Tokyo", 2]], { object: person })
puts view.select(:person, :city_id, [["Paris", 1], ["Tokyo", 2]], { object: person, include_blank: "None" }, { class: "city" })
puts view.select(:person, :city_id, [["Paris", 1]], { object: person, prompt: true }, { required: true })
puts view.select(:person, :name, ["a", "b"], { object: person, selected: "b", disabled: "a" })
puts view.select(:person, :name, [["Group 1", ["a", "b"]], ["Group 2", ["c"]]], { object: person })
puts view.select(:person, :name, {}, {}) { "<option>block</option>".html_safe }
puts view.collection_select(:person, :city_id, people, :id, :name, { object: person, prompt: "Pick" })
puts view.grouped_collection_select(:person, :city_id, continents, :countries, :name, :id, :name, { object: person })
puts view.collection_radio_buttons(:person, :city_id, people, :id, :name, { object: person })
puts view.collection_checkboxes(:person, :city_id, people, :id, :name, { object: person, include_hidden: false })
puts view.collection_check_boxes(:person, :city_id, people, :id, :name, { object: person }) { |b| b.label + b.checkbox }
