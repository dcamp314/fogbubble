def print_tree(n, indent = 0)
  puts "%s%s  (%s%s" % ["  " * indent,
                        n.class.to_s.partition("::").last,
                        n.to_s[0, 58],
                        n.to_s.length > 58 ? "..." : ")"]
  XPath.each(n, "child::node()") { |child| print_tree(child, indent + 1) }
end
