# The class bodies of attributes.rb / attributes.sake: the attributes API, attribute methods and Dirty.
class Product
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Dirty
  include ActiveModel::Serializers::JSON
  attribute :name, :string
  attribute :price, :decimal, precision: 6, scale: 2
  attribute :quantity, :integer, default: 1
  attribute :available, :boolean, default: true
  attribute :released_on, :date
  attribute :weight, :float
  attribute :notes
  attribute_method_suffix "_present?"
  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
end

class Person
  include ActiveModel::Dirty
  include ActiveModel::Serializers::JSON
  attr_accessor :first, :last
  define_attribute_methods :first, :last
  alias_attribute :given, :first
end
