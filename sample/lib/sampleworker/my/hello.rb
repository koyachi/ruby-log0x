module SampleWorker
  module Gearman
    class Hello
      include Log0x::Workerize
      worker_type :gearman => {
        :func => 'addition'
      }

      def work(data,job)
        values = Marshal.load(data)
        p "[#{$$}] SampleWorker::Gearman::Hello  #{data.inspect} #{job.inspect} #{values.inspect}"
        values.first + values.last
      end

      def greet
        'HELLO!!!!, im SampleWorker::Gearman::Hello.'
      end
    end
  end
end
