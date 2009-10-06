require 'rubytree-0.5.2/lib/tree'
require 'yaml'

def do_stuff(context)
  current = context[:current]
  before = current[:before]
  a = before[:a]
  after = {:empty => a != 1}
  current[:after] = after    
  "STUFF!! A=#{a};"
end


root_context = {:root => true, :a => 100}
root = Tree::TreeNode.new("ROOT", root_context)

before = {:before => {:a => 1}}
child = Tree::TreeNode.new("before_0", before)
root << child

context = {:current => before, :tree => root}
puts do_stuff(context)
puts "context after: " + context[:current][:after].to_yaml
before = {:before => {:a => 2}}

child = Tree::TreeNode.new("before_1", before)
root << child
context = {:current => before, :tree => root}

puts do_stuff(context)
puts "context after: " + context[:current][:after].to_yaml