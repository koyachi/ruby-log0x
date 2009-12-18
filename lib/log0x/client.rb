# -*- coding: utf-8 -*-

module Log0x
  class << self
    def enqueue(params)
    end

    alias :insert, :enqueue

    def do_task(params)
    end
  end
end


__END__

投げて終わり(TheSchwartz,Q4M)のとコールバック待って何かするの(Gearman)とあってそのあたりを
吸収するのが難しい

deferred参考にするかなー

