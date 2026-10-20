# class_attribute: a class-level value a subclass inherits until it writes its own.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/core_ext/class/attribute"
require_relative "class_attribute_decl"

p([Base.setting, Sub.setting, SubSub.setting, Other.setting])
Sub.setting = 2
p([Base.setting, Sub.setting, SubSub.setting, Other.setting])
Base.setting = 5
p([Base.setting, Sub.setting, SubSub.setting, Other.setting])
SubSub.setting = 3
p([Base.setting, Sub.setting, SubSub.setting, Other.setting])
p([Base.setting?, Base.respond_to?(:quiet?)])
# A mutable default is shared: an in-place change shows in every class that has not written its own.
Base.tags.push(:a)
p([Base.tags, Sub.tags, Other.tags])
Other.tags = Base.tags + [:b]
p([Base.tags, Sub.tags, Other.tags])
p([Base.name_format, Sub.name_format])
Sub.name_format = "%s!"
p([Base.name_format, Sub.name_format, SubSub.name_format])
