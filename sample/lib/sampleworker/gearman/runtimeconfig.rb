module SampleWorker
  module Gearman
    class RuntimeConfig
      include Log0x::Workerize
      worker_type :gearman

      def init(args)
        @func_name = 'subtraction'
      end

      def work(data,job)
        values = Marshal.load(data)
        p "[#{$$}] SampleWorker::Gearman::RuntimeConfig  #{data.inspect} #{job.inspect} #{values.inspect}"
        values.first - values.last
      end

      def greet
        'HELLO!!!!, im SampleWorker::Gearman::RuntimeConfig.'
      end
    end
  end
end
