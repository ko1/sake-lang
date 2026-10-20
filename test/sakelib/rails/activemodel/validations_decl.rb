# The class bodies of validations.rb / validations.sake: every validator ActiveModel has, and custom ones.
class Signup
  include ActiveModel::Model
  attr_accessor :login, :nickname, :pin, :bio, :code, :age, :score, :count, :ratio, :level
  attr_accessor :email, :size, :color, :plan, :terms, :password, :starts_on, :ends_on, :limit
  validates :login, length: { in: 3..8 }
  validates :nickname, length: { is: 4, wrong_length: "must be exactly %{count} letters" }, allow_nil: true
  validates :pin, length: { minimum: 4, too_short: "needs %{count}" }, format: { without: /[a-z]/ }, allow_blank: true
  validates :bio, length: { maximum: :limit }
  validates :code, absence: true
  validates :age, numericality: { greater_than: 17, less_than_or_equal_to: 120 }
  validates :score, numericality: { in: 1..10 }, allow_nil: true
  validates :count, numericality: { only_integer: true, odd: true }, allow_nil: true
  validates :ratio, numericality: { only_numeric: true, other_than: 0 }, allow_nil: true
  validates :level, numericality: { equal_to: 3 }, allow_nil: true
  validates :email, format: { with: /@/ }, uniqueness_of_domain: true, allow_nil: true
  validates :size, inclusion: { in: %w[S M L], message: "%{value} is not a size" }, allow_nil: true
  validates :color, exclusion: { in: ["red", "blue"] }, allow_nil: true
  validates :plan, inclusion: 1..3, allow_nil: true
  validates :terms, acceptance: true
  validates :password, confirmation: { case_sensitive: false }
  validates :ends_on, comparison: { greater_than: :starts_on }, allow_nil: true
  validates_with PlanValidator, if: :plan
  validates_presence_of :login, message: "is required"
  validates! :count, numericality: { less_than: 100 }, allow_nil: true
  validates :level, presence: true, except_on: :draft
end
