# The class bodies' callback declarations, read by Ruby (require_relative) and by Sake's generator
# (generate "rails/activesupport/active_support/generate/active_support", "callbacks_decl.rb").

class Post
  include ActiveSupport::Callbacks
  define_callbacks :save, :destroy
  set_callback :save, :before, :check
  set_callback :save, :before, :normalize, if: :title?
  set_callback :save, :around, :wrap
  set_callback :save, :after, :log_after
  set_callback :save, :after, :audit, unless: [:draft?, :quiet?]
  set_callback :destroy, :before, :check
  set_callback :destroy, :after, :log_after, prepend: true
end

class Draft < Post
  skip_callback :save, :before, :normalize
  set_callback :save, :after, :notify, prepend: true
  skip_callback :save, :after, :audit, if: :quiet?
  set_callback :save, :before, :check
end

class Controller
  include ActiveSupport::Callbacks
  define_callbacks :process_action, terminator: ->(controller, result_lambda) { result_lambda.call; controller.performed? }, skip_after_callbacks_if_terminated: true
  set_callback :process_action, :before, :authenticate
  set_callback :process_action, :after, :log_action
  set_callback :process_action, :around, :timing
end
