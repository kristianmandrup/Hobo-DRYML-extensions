require 'rubygems'
require 'rubytree-0.5.2/lib/tree.rb'
require 'yaml'

#--------------------------------------------
# DRYML rendering extension
#--------------------------------------------

class DrymlExt

  def initialize(*proc_handlers)
    # initial context tree for view
    @context_tree = Tree::TreeNode.new("ROOT")
    @result_handlers = []         
    # register result handlers
    @result_handlers + proc_handlers.to_a
  end

  def addContext(child_context, child_label, context)
    context << Tree::TreeNode.new(child_label.to_s, child_context)
  end

  def addChildContext(context, arg_item, index)
    # add child context to context before call 
    before = before_context(arg_item)
    child_context = arg_item[:context]
    tag_name = child_context[:tag]
    node_label = "#{tag_name}_#{index}"
    # puts "addChildContext for " + node_label
    child = Tree::TreeNode.new(node_label, before)  
    work_context = context[:current] || context    
    current_node = context[:current_node] || context[:tree]
    # puts "TREE"    
    if current_node
      # puts "Add child node to current node"      
      current_node << child 
    else
      # puts "Missing current node"      
      # puts context.to_yaml      
    end
    # puts "END"
    context[:current_node] = current_node        
        
    # if !work_context[:tree]
    #   work_context[:tree] = child
    # end
    context[:current] = before 
    context[:current_child_node] = child   
    # puts "Tree after addChild:" + node_label
    context[:tree].printTree
    # puts "END"
    # context
  end

  def addReturnContext(context, return_context)
    current_context = context[:current]
    current_context[:after] = return_context
  end

  def call_child_tag(arg_item, context)
    child_exec = arg_item[:exec] 
    tag = arg_item[:context][:tag]
    # puts "call #{tag} with context = \n" + context.to_yaml
    child_exec.call(context)
  end

  def before_context(arg_item)
    {:before => arg_item[:context]}
  end

  # result handler
  def handle_res_1(arg_result, context) 
    current_context = context[:current]
    par_ctx = parent_context(context)
    puts "HANDLER 1"    
    puts "PARENT CTX:" + par_ctx.to_yaml   
    before_ctx = par_ctx[:before]
    if before_ctx
      if before_ctx[:separator] 
        puts "Handle with SEPARATOR!!"       
      end
    end 
    return arg_result, context
  end

    
  def result_handler(arg_result, context) 
   @result_handlers.each do |handler| 
     arg_result, context = handler.call(arg_result, context) 
   end 
   return arg_result, context 
  end

  def parent_context(context)
    current_node = context[:current_node]
    current_context = context[:current]
    current_node_context = context[:current_node].content
    
    # puts "PARENT CONTEXT for " + current_context[:before][:tag]     
    if current_node
      parent_ctx = current_node.content
    else
      parent_ctx = nil
    end
    # puts parent_ctx.to_yaml
    parent_ctx
    # puts "END"
  end
  
  # handles advanced concateration (or whatever is required) when using DRYML
  def concat_ext(context, *args) 
    # puts "CONCAT EXT"
    result_output = "" 
    # must be root if :current has not been set for context
    if context[:root]
      # puts "ROOT context"
      # set root context (is current context in first iteration)
      @context_tree.content = context
      context = {:root => true, :tree => @context_tree}
    else
      # must be a nested call, parent context tree accessible as context[:tree]
      # puts "Nested context"
      parent_context = context[:parent_context]
      # ensure children are added to the correct node of parent context!
      # context[:current_node] should be the target of child nodes added in this iteration
      # TODO: Fix this!!!
      parent_current_node = parent_context[:current_child_node]
      context[:current_node] = parent_current_node
      # puts "Current node"
      parent_current_node.to_yaml
    end

    # puts "CONTEXT BEFORE LOOP"
    # puts context.to_yaml
    
    # puts "args count: #{args.size};"  
    args.each_with_index do |arg_item, index| 
      arg_context = arg_item[:context]
      arg_tag = arg_context[:tag]
      # puts "arg #{index}:" + arg_context.to_yaml

      # puts "TAG:" + arg_tag

      # puts "Add child context"
      # add child context to current context
      addChildContext(context, arg_item, index)    

      # call child element with full context 
      # puts "Call child proc for tag: " + arg_tag  
      # puts "call tag=#{arg_tag} with context = \n" + context.to_yaml             
      arg_result = call_child_tag(arg_item, context)
            
      # puts "RESULT HANDLER"
      # puts arg_result.to_yaml
      # puts context.to_yaml
            
      sub_result_output, return_context = result_handler(arg_result, context) 
      # puts "SUB RESULT:"
      puts sub_result_output.to_yaml

      # puts "RETURN CONTEXT:"
      # puts return_context.to_yaml

      # TODO: externalise this using result handler?
      result_output << sub_result_output 
      # puts "RESULT OUTPUT after add:"      
      # puts result_output

      # add child return context to current context
      # addReturnContext(context, return_context)
    end
    # return 
    return result_output 
  end 
end


#--------------------------------------------
# To be put in ApplicationHelper or similar
#--------------------------------------------

p1 = Proc.new {|c,a| handle_res_1(c,a) }
@dryml_ext = DrymlExt.new(p1)

def concat_ext(context, *args)  
  @dryml_ext.concat_ext(context, *args)
end  


#--------------------------------------------
# An example of a simple DRYML tag method (to be generated by tag def when DRYML compiles a tag!)
#----------------------------------------------
def do_stuff(context)
  current = context[:current]
  # get :before context
  before = current[:before]
  # get variables needed for this tag
  # NOTE: you could also travel the context-tree for other context vars, fx parent/ancestor context vars, using regular RubyTree methods 
  a = before[:a]

  # populate :after context 
  after = {:empty => a != 1}
  current[:after] = after    
  
  return "STUFF!! A=#{a};"
end

output, context = concat_ext(
 {:root => true, :tag => 'root'},
 {
   :context => {:a => 1, :tag => 'a', :separator => true},
   :exec => Proc.new {|parent_context| concat_ext(
     {:nested => true, :parent_context => parent_context, :tree => parent_context[:tree]},
     {
       :context => {:a => 22, :tag => 'c'},
       :exec => Proc.new {|x| do_stuff(x)}
     },
     {
       :context => {:a => 33, :tag => 'c'},
       :exec => Proc.new {|x| do_stuff(x)}
     }

   )}
 },
 {
    :context => {:a => 4, :tag => 'a'},
    :exec => Proc.new {|x| do_stuff(x)}
 } 
)


# #----------------------------------------------
# # Example of DRYML generated erb code that should render the page!
# #----------------------------------------------
# output, context = concat_ext(
#  {:root => true, :tag => 'root'},
#  {
#    :context => {:a => 1, :tag => 'a'},
#    :exec => Proc.new {|x| do_stuff(x)}
#  },
#  # this is a wrapper tag! indicated separator to be used!
#  {
#    :context => {:tag => 'b', :separator => true},
#    :exec => Proc.new {|parent_context| 
#      # join each result with comma between (examine parent context to see this! context[:current][:tree].parent[:context] ?)
#      concat_ext(
#      {:nested => true, :tree => parent_context[:tree]},
#      {
#        :context => {:a => 3, :tag => 'c'},
#        :exec => Proc.new {|x| do_stuff(x)}
#      }
#      # ,{
#      #   :context => {:a => 4, :tag => 'a'},
#      #   :exec => Proc.new {|x| do_stuff(x)}
#      # }     
#      )
#    }
#  }
# )

puts "FINAL OUTPUT:\n"
puts output

# concat_ext(
#  {:context => {:a => 1, :root => true},
#   :exec => concat_ext({
#          :context => {:a => 2},
#          :exec => Proc.new {|x| do_stuff(x)}
#   })
#  },
#  {
#    :context => {:a => 3},
#    :exec => Proc.new {|x| do_stuff(x)}
#  }
# )

