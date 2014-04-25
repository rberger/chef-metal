require 'cheffish'
require 'cheffish/cheffish_server_api'

module ChefMetal
  #
  # Specification for a machine. Sufficient information to find and contact it
  # after it has been set up.
  #
  class MachineSpec
    def initialize(node, chef_server)
      @node = node
      @chef_server = chef_server
    end

    def self.get(name, chef_server)
      rest = Cheffish::CheffishServerAPI.new(chef_server || Cheffish.current_chef_server)
      MachineSpec.new(rest.get("/nodes/#{name}"), chef_server)
    end

    #
    # Name of the machine. Corresponds to the name in "machine 'name' do" ...
    #
    def name
      @node['name']
    end

    #
    # URL of the chef server where this node is/will be stored.
    #
    def chef_server
      @chef_server
    end

    #
    # URL of the driver.
    #
    def driver_url
      metal_attr('driver_url')
    end

    #
    # Spec of this machine (its location and information for the driver to look
    # it up). This should be a freeform hash, with enough information for the
    # driver to look it up and create a Machine object to access it.
    #
    # chef-metal will do its darnedest to not lose this information.
    #
    def spec
      metal_attr('spec')
    end

    #
    # Set the spec for this machine.
    #
    def spec=(value)
      @node['normal']['metal'] ||= {}
      @node['normal']['metal']['spec'] = value
    end

    #
    # The Chef node representing this machine.  You may modify the node to save
    # information out.
    #
    def node
      @node
    end

    #
    # Save this node to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  Data will be
    # saved automatically for you after allocate_machine and ready_machine.
    #
    def save_to_server(action_handler)
      # Save the node to the server.
      ChefMetal.inline_resource(action_handler) do
        chef_node node['name'] do
          chef_server chef_server
          raw_json node
        end
      end
    end

    private

    def metal_attr(attr)
      if @node['normal'] && @node['normal']['metal']
        @node['normal']['metal'][attr]
      else
        nil
      end
    end
  end
end
