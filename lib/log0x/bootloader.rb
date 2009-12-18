# -*- coding: utf-8 -*-
module Log0x
  module BootLoader
    class << self
      def workers
        @workers ||= []
      end

      # @workersみて何かするメソッドここらへんに

      WORKER_MODULE_NAMES = {
        # この時点で名前解決できないのでクラス名は文字列で
        :q4m => 'Log0x::Worker::Q4M',
        :gearman => 'Log0x::Worker::Gearman',
      }
#      def add_worker_module(id, worker_module)
#        WORKER_MODULE_NAMES[id] = worker_module.to_s
#      end

      # gearmanはベースクラスがあるわけじゃないのでワーカー種別毎に判断する実装がわかれる
      def supported?(worker_class)
        worker_class.ancestors.include? ::Log0x::Workerize
      end

      def start(worker_class, process_config, global_config)
        worker_module_name = WORKER_MODULE_NAMES[worker_class.worker_type] || nil
        abort "UNKNOWN WORKER!!! (#{worker_class.worker_type})" unless worker_module_name

        root = Module
        concreate_worker_module = worker_module_name.split('::').inject(root){|parent,child| parent.const_get child}

        # worker_typeを元に具体的なworker機能を追加する
        worker_class.extend concreate_worker_module

        concreate_worker_module.start process_config.merge({
                                                             'worker_class' => worker_class,
                                                             'worker_common' => global_config['worker_common']
                                                           })
      end
    end
  end
end
