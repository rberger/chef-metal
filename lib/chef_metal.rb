# Include recipe basics so require 'chef_metal' will load everything
require 'chef_metal/recipe_dsl'
require 'chef/resource/machine'
require 'chef/provider/machine'
require 'chef/resource/machine_batch'
require 'chef/provider/machine_batch'
require 'chef/resource/machine_file'
require 'chef/provider/machine_file'
require 'chef/resource/machine_execute'
require 'chef/provider/machine_execute'

require 'chef_metal/inline_resource'

module ChefMetal
  def self.with_driver(driver)
    old_driver = ChefMetal.current_driver
    ChefMetal.current_driver = driver
    if block_given?
      begin
        yield
      ensure
        ChefMetal.current_driver = old_driver
      end
    end
  end

  def self.with_machine_options(machine_options)
    old_machine_options = ChefMetal.current_machine_options
    ChefMetal.current_machine_options = machine_options
    if block_given?
      begin
        yield
      ensure
        ChefMetal.current_machine_options = old_machine_options
      end
    end
  end

  def self.with_machine_batch(machine_batch)
    old_machine_batch = ChefMetal.current_machine_batch
    ChefMetal.current_machine_batch = machine_batch
    if block_given?
      begin
        yield
      ensure
        ChefMetal.current_machine_batch = old_machine_batch
      end
    end
  end


  def self.inline_resource(action_handler, &block)
    InlineResource.new(action_handler).instance_eval(&block)
  end

  @@current_machine_batch = nil
  def self.current_machine_batch
    @@current_machine_batch
  end
  def self.current_machine_batch=(machine_batch)
    @@current_machine_batch = machine_batch
  end

  @@current_driver = nil
  def self.current_driver
    @@current_driver
  end
  def self.current_driver=(driver)
    @@current_driver = driver
  end

  @@current_machine_options = nil
  def self.current_machine_options
    @@current_machine_options
  end

  def self.current_machine_options=(machine_options)
    @@current_machine_options = machine_options
  end

  # Helpers for driver inflation
  @@registered_driver_classes = {}
  def self.add_registered_driver_class(name, driver)
    @@registered_driver_classes[name] = driver
  end

  def self.driver_for_url(url)
    if !spec.driver_url
      raise "Node #{name} was not provisioned with Metal."
    end
    cluster_type = spec.driver_url.split(':', 2)[0]
    begin
      require "chef_metal/driver_init/#{cluster_type}_init"
    rescue LoadError
      Chef::Log.error("Node #{spec.name} registered with driver #{spec.driver_url}, but could not require 'chef_metal/driver_init/#{cluster_type}_init'")
      raise
    end
    driver_class = @@registered_driver_classes[cluster_type]
    driver_class.new(driver_url)
  end

  def self.connect_to_machine(name, chef_server = nil)
    spec = MachineSpec.get(name, chef_server)
    driver = driver_for_url(spec.driver_url)
    machine = driver.connect_to_machine(spec)
    [ machine, driver ]
  end
end
