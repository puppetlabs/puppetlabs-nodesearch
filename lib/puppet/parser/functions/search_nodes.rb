require 'puppet/face'
Puppet::Parser::Functions.newfunction(:search_nodes, :type => :rvalue) do |args|

  @doc =  '
Takes a hash of the filters that will be used to create
the list of hosts.

  keys of the form: facts.somefact are filters based on facts
  a key of the form: classes createa filter based on classes

Second argument is a fact to return, if ommited return an array of hashes of all facts of the nodes
'

  facts_filter = args[0] || {}
  class_filter = facts_filter.delete('classes') || []
  facts_filter.each do |name, value|
    unless name =~ /^facts\./
      raise Puppet::Error, "filter: #{name}, is not prefixed with facts."
    end
  end
  #expiration_time = args[2] || 60
  # TODO - support some expiration time
  debug("Searching for nodes")
  facts_search_nodes = Puppet::Face[:facts, :current].search('fake_key', {:extra => facts_filter})
  class_search_nodes = Puppet::Face[:hostclass, :current].search({:classes => class_filter})
  if facts_filter.empty? or class_filter.empty?
    nodes = facts_search_nodes | class_search_nodes
  else
    nodes = facts_search_nodes & class_search_nodes
  end
  debug("Found %d nodes, fetching facts" % nodes.count)
  nodes = nodes.map { |node| Puppet::Face[:facts, :current].find(node).values }
  if args[1]
    debug("Selecting fact #{args[1]}")
    nodes.map { |node| node[args[1]] }
  else
    nodes
  end
end
