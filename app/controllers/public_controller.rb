class PublicController < ApplicationController
  def up
    render json: { up: true }
  end

  def sleep
    delayed_render do |delay|
      Kernel.sleep(delay)
    end
  end

  def wait
    delayed_render do |delay|
      init_time = DateTime.now
      while (DateTime.now.to_f - init_time.to_f) < delay
        # do nothing
      end
    end
  end

  private

  def delayed_render
    request_start = headers['X-Request-Start'].presence&.yield_self {|t| Time.at(t.to_f).to_datetime } || DateTime.now
    request_processing_start = DateTime.now
    yield params[:delay].to_f
    request_processing_end = DateTime.now

    request_processing_time = request_processing_end.to_f - request_processing_start.to_f
    queue_time = request_processing_start.to_f - request_start.to_f

    result = {
      processing_overhead: request_processing_time - params[:delay].to_f,
      queue_time: queue_time,

      request_start_raw: headers['X-Request-Start'],
      request_start: request_start,
      request_processing_start: request_processing_start,
      request_processing_end: request_processing_end,
      request_processing_time: request_processing_time,
      delay: params[:delay].to_f,
    }

    padding = result.keys.map(&:to_s).map(&:length).max
    result_table = result.map{|k,v| "#{k.to_s.ljust(padding)}  #{v}"}.join("\n")

    render plain: "#{result_table}\n\n#{result.to_json}"
  end

end
