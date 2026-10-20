gem "actionview", "8.1.3"
require "action_view"

view = ActionView::Base.empty

p view.number_to_phone(5551234)
p view.number_to_phone("5551234")
p view.number_to_phone(1235551234, area_code: true)
p view.number_to_phone(1235551234, delimiter: " ", country_code: 1, extension: 555)
p view.number_to_phone(nil)
p view.number_to_currency(1234567890.50)
p view.number_to_currency(1234567890.506, precision: 3)
p view.number_to_currency(-1234567890.50, negative_format: "(%u%n)")
p view.number_to_currency(1234567890.50, unit: "&pound;", separator: ",", delimiter: "", format: "%n %u")
p view.number_to_currency(1234567890.50, unit: "&pound;".html_safe)
p view.number_to_currency("123a456")
p view.number_to_percentage(100)
p view.number_to_percentage(302.24398923423, precision: 5)
p view.number_to_percentage(1000, delimiter: ".", separator: ",")
p view.number_to_percentage("98a")
p view.number_with_delimiter(12345678)
p view.number_with_delimiter(12345678.05)
p view.number_with_delimiter(12345678, delimiter: ".")
p view.number_with_delimiter("<b>123456</b>")
p view.number_with_precision(111.2345)
p view.number_with_precision(111.2345, precision: 2)
p view.number_with_precision(13, precision: 5, significant: true)
p view.number_with_precision(389.32314, precision: 4, significant: true)
p view.number_with_precision(13.00, precision: 5, strip_insignificant_zeros: true)
p view.number_to_human_size(123)
p view.number_to_human_size(1234567)
p view.number_to_human_size(1234567890, precision: 2)
p view.number_to_human(123)
p view.number_to_human(1234567)
p view.number_to_human(489939, precision: 4)
p view.number_to_human(1234567, units: { unit: "m", thousand: "km" })
p view.number_to_currency(12.5).html_safe?, view.number_to_currency("x").html_safe?
begin
  view.number_to_currency("12x", raise: true)
rescue ActionView::Helpers::NumberHelper::InvalidNumberError => e
  p e.number
end
begin
  view.number_to_phone("abc", raise: true)
rescue ActionView::Helpers::NumberHelper::InvalidNumberError => e
  p e.number
end
