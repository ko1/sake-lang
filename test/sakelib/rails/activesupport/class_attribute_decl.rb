# The class bodies, read by Ruby (require_relative) and by Sake's generator
# (generate "rails/activesupport/active_support/generate/active_support", "class_attribute_decl.rb").

class Base
  class_attribute :setting, default: 1
  class_attribute :tags, default: []
  class_attribute :name_format, :quiet, instance_predicate: false
end

class Sub < Base
end

class SubSub < Sub
end

class Other < Base
end
