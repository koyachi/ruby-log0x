# -*- coding: utf-8 -*-
module SampleWorker
  module Q4M
    class GutenMorgen
      include Log0x::Workerize
      worker_type :q4m => {
        :queues => 'my_queue',
      }

      def work(job, queue)
        p "[#{$$}] SampleWorker::Q4M::GutenMorgen  #{job[:v1].to_i} #{job[:v2].to_i}"
      end

      def greet
        'GutenMorgen, im SampleWorker::Q4M::GutenMorgen.'
      end
    end
  end
end
