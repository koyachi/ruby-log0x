# -*- coding: utf-8 -*-
module Log0x
  module Worker
    module Common
      def self.extended(worker)
        worker.instance_variable_set(:@worker_type, nil)
        worker.instance_variable_set(:@info, nil)
        Log0x::BootLoader.workers.push worker
      end

      def worker_type(opt=nil)
        if opt && opt.instance_of?(Hash)
          @worker_type = opt.keys[0]
          @info = opt[@worker_type]
          # @worker_type指定のみで@infoはconfigから読めるようにもしておきたい
        elsif opt && opt.instance_of?(Symbol)
          @worker_type = opt
          @info = nil
        end
        @worker_type
      end
    end
  end

  # ユーザのワーカー実装クラスがインクルードするモジュール
  module Workerize
    def self.included(worker)
      worker.extend ::Log0x::Worker::Common
    end
  end
end
