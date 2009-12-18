# -*- coding: utf-8 -*-
module Log0x
  module Worker
    module Q4M
      def self.extended(worker)
        info = worker.instance_variable_get(:@info)
        worker.instance_variable_set(:@queue_tables, info[:queues])
        worker.module_eval do |mod|
          include ::Q4M::Worker
          def initialize(*args)
            @queue_tables = self.class.instance_variable_get(:@queue_tables)# || ::Log0x.config['worker_common']['q4m']
          end
        end
      end

      def work(data, job)
        raise Log0x::WorkerMethodNotImplemented
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
