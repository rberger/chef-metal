module ChefMetal
  #
  # A Driver instance represents a place where machines can be created and found,
  # and contains methods to create, delete, start, stop, and find them.
  #
  # For AWS, a Driver instance corresponds to a single account.
  # For Vagrant, it is a directory where VM files are found.
  #
  # == How to Make a Driver
  #
  # To implement a Driver, you must implement the following methods:
  #
  # - initialize(driver_url) - create a new driver with the given URL
  # - driver_url - a URL representing everything unique about your provider.
  #                But NOT credentials.
  # - allocate_machine - ask the driver to allocate a machine to you.
  # - ready_machine - get the machine "ready" - wait for it to be booted and
  #                   accessible (for example, accessible via SSH transport).
  # - stop_machine - stop the machine.
  # - delete_machine - delete the machine.
  #
  # Optionally, you can also implement:
  # - allocate_machines - allocate an entire group of machines.
  # - resource_created - a hook to tell you when a resource associated with your
  #                      provider has been created.
  #
  # Additionally, you must create a file named `chef_metal/driver_init/<scheme>_init.rb`,
  # where <scheme> is the name of the scheme you chose for your driver_url. This
  # file, when required, must call
  #
  # All of these methods must be idempotent - if the work is already done, they
  # just don't do anything.
  #
  class Driver
    #
    # Inflate a driver from node information; we don't want to force the
    # driver to figure out what the driver really needs, since it varies
    # from driver to driver.
    #
    # ## Parameters
    # driver_url - the URL to inflate the driver
    #
    # ## Returns
    # A Driver representing the given driver_url.
    def initialize(driver_url)
      # We do not save it ... it's up to the driver to extract whatever information
      # it wants.
    end

    #
    # A URL representing the driver and the place where machines come from.
    # This will be stuffed in attributes in the node so that the node can be
    # reinflated.  URLs must have a unique scheme identifying the driver
    # class, and enough information to identify the place where created machines
    # can be found.  For AWS, this is the account number; for lxc and vagrant,
    # it is the directory in which VMs and containers are.
    #
    # For example:
    # - fog:AWS:123456789012
    # - vagrant:/var/vms
    # - lxc:
    # - docker:
    #
    def driver_url
      raise "#{self.class} does not implement driver_url"
    end

    #
    # Allocate a machine from the PXE/cloud/VM/container provider.  This method
    # does not need to wait for the machine to boot or have an IP, but it must
    # store enough information in node['normal']['driver_output'] to find
    # the machine later in ready_machine.
    #
    # If a machine is powered off or otherwise unusable, this method may start
    # it, but does not need to wait until it is started.  The idea is to get the
    # gears moving, but the job doesn't need to be done :)
    #
    # ## Parameters
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a provider, but could be anything that can support the
    #        interface (i.e., in the case of the test kitchen metal driver for
    #        acquiring and destroying VMs).
    #
    # existing_machine - a MachineSpec representing the existing machine (if any).
    #
    # machine_options - a set of options representing the desired provisioning
    #                   state of the machine (image name, bootstrap ssh credentials,
    #                   etc.). This will NOT be stored in the node, and is
    #                   ephemeral.
    #
    # ## Returns
    #
    # Modifies the passed-in machine_spec.  Anything in here will be saved
    # back to the node.
    #
    def allocate_machine(action_handler, machine_spec, machine_options)
      raise "#{self.class} does not implement allocate_machine"
    end

    #
    # Ready a machine, to the point where it is running and accessible via a
    # transport. This will NOT allocate a machine, but may kick it if it is down.
    # This method waits for the machine to be usable, returning a Machine object
    # pointing at the machine, allowing useful actions like setup, converge,
    # execute, file and directory.
    #
    # ## Parameters
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a provider, but could be anything that can support the
    #        interface (i.e., in the case of the test kitchen metal driver for
    #        acquiring and destroying VMs).
    # machine_spec - MachineSpec representing this machine.
    #
    # ## Returns
    #
    # Machine object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.
    #
    def ready_machine(action_handler, machine_spec)
      raise "#{self.class} does not implement ready_machine"
    end

    #
    # Connect to a machine without allocating or readying it.  This method will
    # NOT make any changes to anything, or attempt to wait.
    #
    # ## Parameters
    # machine_spec - MachineSpec representing this machine.
    #
    # ## Returns
    #
    # Machine object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.
    #
    def connect_to_machine(machine_spec)
      raise "#{self.class} does not implement connect_to_machine"
    end

    #
    # Delete the given machine (idempotent).  Should destroy the machine,
    # returning things to the state before allocate_machine was called.
    #
    def delete_machine(action_handler, machine_spec)
      raise "#{self.class} does not implement delete_machine"
    end

    #
    # Stop the given machine.
    #
    def stop_machine(action_handler, machine_spec)
      raise "#{self.class} does not implement stop_machine"
    end

    #
    # Optional interface methods
    #

    #
    # Allocate a set of machines.  This should have the same effect as running
    # allocate_machine on all nodes.
    #
    # Drivers do not need to implement this; the default implementation
    # calls acquire_machine in parallel.
    #
    # ## Parameter
    # action_handler - the action_handler object that is calling this method; this
    #        is generally a provider, but could be anything that can support the
    #        interface (i.e., in the case of the test kitchen metal driver for
    #        acquiring and destroying VMs).
    # nodes - a list of nodes representing the nodes to acquire.
    # parallelizer - an object with a parallelize() method that works like this:
    #
    #   parallelizer.parallelize(nodes) do |node|
    #     allocate_machine(action_handler, node)
    #   end.to_a
    #   # The to_a at the end causes you to wait until the parallelization is done
    #
    # This object is shared among other chef-metal actions, ensuring that you do
    # not go over parallelization limits set by the user.  Use of the parallelizer
    # to parallelizer machines is not required.
    #
    def allocate_machines(action_handler, nodes, parallelizer)
      parallelizer.parallelize(nodes) do |node|
        allocate_machine(action_handler, node)
      end.to_a
    end

    #
    # Provider notification that happens at the point a machine resource is declared
    # (after all properties have been set on it)
    #
    def resource_created(machine)
    end
  end
end
