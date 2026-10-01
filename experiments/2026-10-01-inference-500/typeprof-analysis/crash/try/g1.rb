counts = {4 => 1}
counts.to_a.each_slice(125) do |block|
  block.max_by { |_, c| c }
end
