# The class bodies of callbacks.rb / callbacks.sake: define_model_callbacks and validation callbacks.
class Account
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks
  extend ActiveModel::Callbacks
  attr_accessor :name, :balance, :frozen_account
  define_model_callbacks :save
  define_model_callbacks :close, only: [:before, :after]
  before_validation :normalize_name
  before_validation :set_default_balance, on: :create
  after_validation :log_validation
  validates :name, presence: true
  before_save :check_frozen
  before_save :announce, if: :big?
  around_save :wrap
  after_save :saved
  after_save :audit, unless: :quiet?
  before_close :closing
  after_close :closed
end
