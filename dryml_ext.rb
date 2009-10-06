require 'context.rb'
#--------------------------------------------
# DRYML rendering extension
#--------------------------------------------

class DrymlExt

  def initialize(config)
    # initial context tree for view
    @context_tree = Tree::TreeNode.new("ROOT")
    
    @init_result = config[:init_result] || ""
    hsr = Proc.new {|result_output, sub_result_output, ctx| default_add_tag_result(result_output, sub_result_output)}
    @handle_sub_result = config[:handle_sub_result] || hsr
    
    har = Proc.new {|results, ctx| results }    
    @handle_all_results = config[:handle_all_results] || har
    
    # initialize content result handlers
    @result_handlers = config[:handlers] || []             
  end

  def default_add_tag_result(result_output, sub_result_output)
    result_output << sub_result_output 
  end


  # execute a child tag Proc with the current context
  def do_child_tag(arg_item, context)
    # get child tag execution proc
    child_exec = arg_item[:exec]
    # get child (private) context for execution
    child_context = arg_item[:context] 
    tag = arg_item[:context][:tag]
    # merge child context into current context before call
    context[:current].merge!(child_context)
    child_exec.call(context)
  end

  
  # for each result handler execute it to have a chance to mutate the 
  # final result based on the context  
  def execute_result_handlers(arg_result, context) 
   @result_handlers.each do |handler| 
     arg_result, context = handler.call(arg_result, context) 
   end 
   return arg_result, context 
  end

  # initialize context in start of loop
  def init_context(context)
    if context[:root]
      # set context tree root to context
      @context_tree.content = context
      # merge initial context tree into root context
      context.merge!({:tree => @context_tree})
    else
      # must be a nested call, parent context tree accessible as context[:tree]
      parent_context = context[:parent_context]
      # ensure children are added to the correct node of parent context!
      # context[:current_node] should be the target of child nodes added in this iteration
      parent_current_node = parent_context[:current_child_node]
      context[:current_node] = parent_current_node
    end
    return context, parent_context, parent_current_node
  end    
  
  
  # handles advanced concateration (or whatever is required) when using DRYML
  def concat_ext(context, *args) 
    result_output = @init_result.call
    context, parent_context, parent_current_node = init_context(context)
    
    args.each_with_index do |arg_item, index| 
      arg_context = arg_item[:context]
      arg_tag = arg_context[:tag]

      # add child context to current context
      Context::add_child(context, arg_item, index)    

      # call child element with full context 
      arg_result = do_child_tag(arg_item, context)
            
      sub_result_output, return_context = execute_result_handlers(arg_result, context) 

      # add child return context to current context
      Context::add_return(context, return_context)

      # handle sub result
      @handle_sub_result.call(result_output, sub_result_output, context)
    end
    return @handle_all_results.call(result_output, context)
  end 
end
