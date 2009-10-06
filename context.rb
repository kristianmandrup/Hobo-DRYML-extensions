class Context
  
  # create new tree node with child context and add to existing context node
  def self.add_node(child_context, child_label, context_node)
    context_node << Tree::TreeNode.new(child_label.to_s, child_context)
  end

  def self.add_child(context, arg_item, index)
    # add child context to context before call 
    before = before(arg_item)
    child_context = arg_item[:context]
    tag_name = child_context[:tag]
    node_label = "#{tag_name}_#{index}"
    child = Tree::TreeNode.new(node_label, before)  
    work_context = context[:current] || context    
    current_node = context[:current_node] || context[:tree]
    if current_node
      current_node << child 
    end
    context[:current_node] = current_node                
    context[:current] = before 
    context[:current_child_node] = child   
  end

  def self.add_return(context, return_context)
    current_context = context[:current]
    current_context[:after] = return_context
  end  
  
  def self.before(arg_item)
    {:before => arg_item[:context]}
  end
  
  def self.parent(context)
    current_node = context[:current_node]
    current_context = context[:current]
    current_node_context = context[:current_node].content
    if current_node
      parent_ctx = current_node.content
    else
      parent_ctx = nil
    end
    parent_ctx
  end  
  
end