# -*- coding: utf-8 -*-
# worker_typeだけ先に教えてワーカーコンフィグはインスタンス生成時に指定する例
module SampleWorker
  module Q4M
    class RuntimeConfig
      include Log0x::Workerize
      worker_type :q4m

      def init(args)
        @queue_tables = args['queue_tables']
        p "[#{$$}] SampleWorker::Q4M::RuntimeConfig#init #{@queue_tables}"
      end

      def work(job, queue)
        p "[#{$$}] SampleWorker::Q4M::RuntimeConfig#work  #{job[:v1].to_i} #{job[:v2].to_i}"
      end

      def greet
        'ohayo-, im SampleWorker::Q4M::RuntimeConfig.'
      end
    end
  end
end
