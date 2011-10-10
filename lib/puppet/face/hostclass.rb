require 'puppet/face'
require 'active_record'
require 'puppet/rails'
require 'puppet/rails/resource'

Puppet::Face.define(:hostclass, '0.0.1') do

  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"

  action(:search) do
    summary 'list nodes whose latest catalog contains a class'
    option '--classes classes' do
      summary 'classes to filter on'
    end
    option '--result_combine operator' do
      summary 'rather to combine searches using "and" or "or"'
    end
    when_invoked do |options|
      return [] unless options[:classes]
      klasses = if options[:classes].is_a?(Array)
        options[:classes]
      elsif options[:classes].is_a?(String)
        options[:classes].split(/\s*,\s*/)
      else
      end
      operator = options[:result_combine] ? options[:result_combine].to_sym : :intersection
      # this is required to establish the connection
      Puppet::Rails.init
      # collect the nodes that contain a single class
      nodes = klasses.collect do |class_name|
        # it may be faster to combine the classes into a single query
        nodes = Puppet::Rails::Resource.find_by_sql("SELECT hosts.name as host_name FROM resources INNER JOIN hosts ON hosts.id = resources.host_id WHERE resources.title='#{class_name}' and resources.restype='class';")
        nodes.map { |n| n.host_name }
      end
      if operator == :intersection
        # only return the nodes that contain all of the classes
        # I would use inject, but I want to support 1.8.5
        intersected_nodes = nodes.pop || []
        nodes.each do |node_list|
          intersected_nodes = intersected_nodes & node_list
        end
        intersected_nodes
      elsif operator == :union
        nodes.flatten.uniq
      else
        raise ArgumentError, "Invaid option for result_combine #{operator}"
      end
    end
  end
end
