# -*- coding: utf-8 -*-
module Log0x
  module Worker
    module Gearman
      def self.extended(worker)
        info = worker.instance_variable_get(:@info)
        worker.instance_variable_set(:@func_name, info[:func])
        worker.module_eval do |mod|
          attr_accessor :func_name
          def initialize(*args)
            @func_name = self.class.instance_variable_get(:@func_name)
          end
        end
      end

      def work(data,job)
        raise Log0x::WorkerMethodNotImplemented
      end

      def self.start(args)
        @impl = args['worker_class'].new
        @worker = ::Gearman::Worker.new args['worker_common']['gearman']['servers']
        @worker.add_ability(@impl.func_name) do |data, job|
          @impl.work data, job
        end

        loop do
          @worker.work
        end
      end
    end
  end
end