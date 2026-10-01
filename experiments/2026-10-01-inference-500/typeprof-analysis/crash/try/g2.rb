[[4, 1]].each_slice(125) do |block|
  block.max_by { |_, c| c }
end
