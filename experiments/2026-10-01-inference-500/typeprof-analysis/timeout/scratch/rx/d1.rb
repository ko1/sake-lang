def to_doc(value)
  case value
  when Hash then value.map { |k, v| to_doc(v) }
  else value.to_s
  end
end
p to_doc({"a" => {"b" => 1}})
