begin
  require 'vagrant'
rescue LoadError
  raise 'The vagrant-registration plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant RHEL plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
  module Registration
    class Plugin < Vagrant.plugin("2")
      class << self
        def register(hook)
          setup_logging
          hook.after(::Vagrant::Action::Builtin::SyncedFolders,
                     VagrantPlugins::Registration::Action.action_register)
        end

        def unregister(hook)
          setup_logging
          hook.prepend(VagrantPlugins::Registration::Action.action_unregister)
        end
      end

      name "Registration"
      description <<-DESC
      This plugin adds register and unregister functionality to Vagrant Guests that 
      support the capability
      DESC

      action_hook(:registration_register, :machine_action_up, &method(:register))
      action_hook(:registration_register, :machine_action_provision, &method(:register))
      action_hook(:registration_unregister, :machine_action_halt, &method(:unregister))
      action_hook(:registration_unregister, :machine_action_destroy, &method(:unregister))

      config(:registration) do
        require_relative 'config'
        Config
      end

      # This sets up our log level to be whatever VAGRANT_LOG is
      # for loggers prepended with 'vagrant_libvirt'
      def self.setup_logging
        require 'log4r'
        level = nil
        begin
          level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end
        # Some constants, such as "true" resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil if !level.is_a?(Integer)
        # Set the logging level on all "vagrant" namespaced
        # logs as long as we have a valid level.
        if level
          logger = Log4r::Logger.new('vagrant_registration')
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end
    end
  end
end
