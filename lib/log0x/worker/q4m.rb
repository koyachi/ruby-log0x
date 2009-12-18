# -*- coding: utf-8 -*-
module Log0x
  module Worker
    module Q4M
      def self.extended(worker)
        info = worker.instance_variable_get(:@info)
        worker.instance_variable_set(:@queue_tables, (info.instance_of? Hash) ? info[:queues] : nil)
        worker.module_eval do |mod|
          include ::Q4M::Worker
          def initialize(*args)
            predefined_queue_tables = self.class.instance_variable_get(:@queue_tables)
            @queue_tables = predefined_queue_tables if predefined_queue_tables
            init(args) if methods.include? 'init'
          end
        end
      end

      def self.start(args)
        @workers = args['worker_class']
        ci = args['worker_common']['q4m']['connect_info']
        dsn = ci['dsn'] || ''
        user = ci['user'] || ''
        pswd = ci['pswd'] || ''
        @q = ::Q4M.connect :connect_info => [dsn, user, pswd]
        @q.start_worker @workers
      end
    end
  end
end
