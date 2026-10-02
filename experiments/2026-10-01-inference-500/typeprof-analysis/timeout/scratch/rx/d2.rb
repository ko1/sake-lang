def to_doc(value)
  case value
  when Hash then value.map { |kv| to_doc(kv[1]) }
  else value.to_s
  end
end
p to_doc({"a" => {"b" => 1}})
