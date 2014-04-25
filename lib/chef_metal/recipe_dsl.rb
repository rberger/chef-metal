require 'chef_metal'

class Chef
  class Recipe
    def with_driver(driver, &block)
      ChefMetal.with_driver(driver, &block)
    end

    def with_machine_options(machine_options, &block)
      ChefMetal.with_machine_options(machine_options, &block)
    end

    def with_machine_batch(the_machine_batch, options = {})
      if the_machine_batch.is_a?(String)
        the_machine_batch = machine_batch the_machine_batch do
          if options[:action]
            action options[:action]
          end
          if options[:max_simultaneous]
            max_simultaneous options[:max_simultaneous]
          end
        end
      end
      ChefMetal.with_machine_batch(the_machine_batch)
    end
  end
end
