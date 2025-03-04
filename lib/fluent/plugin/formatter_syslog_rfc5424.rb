require 'rfc5424/formatter'

module Fluent
  module Plugin
    class FormatterSyslogRFC5424 < Formatter
      Fluent::Plugin.register_formatter('syslog_rfc5424', self)

      config_param :rfc6587_message_size, :bool, default: true
      config_param :hostname_field, :string, default: "hostname"
      config_param :app_name_field, :string, default: "app_name"
      config_param :proc_id_field, :string, default: "proc_id"
      config_param :message_id_field, :string, default: "message_id"
      config_param :structured_data_field, :string, default: "structured_data"
      config_param :log_field, :string, default: "log"

      def configure(conf)
        super
        @hostname_field_array = @hostname_field.split(".")
        @app_name_field_array = @app_name_field.split(".")
        @proc_id_field_array = @proc_id_field.split(".")
        @message_id_field_array = @message_id_field.split(".")
        @structured_data_field_array = @structured_data_field.split(".")
        @log_field_array = @log_field.split(".")
      end

      def format(tag, time, record)
        log.debug("Record")
        log.debug(record.map { |k, v| "#{k}=#{v}" }.join('&'))

        msg = RFC5424::Formatter.format(
          log: record.dig(*@log_field_array) || "-",
          timestamp: time,
          hostname: record.dig(*@hostname_field_array) || "-",
          app_name: record.dig(*@app_name_field_array) || "-",
          proc_id: record.dig(*@proc_id_field_array) || "-",
          msg_id: record.dig(*@message_id_field_array) || "-",
          sd: parse_structured_data(record)
        )

        log.debug("RFC 5424 Message")
        log.debug(msg)

        return msg + "\n" unless @rfc6587_message_size

        msg.length.to_s + ' ' + msg
      end

      def parse_structured_data(record)
        sd_array = []
        @structured_data_field_array.each do |sd_field|
          sd_array << RFC5424::StructuredData.new(sd_id: sd_field , sd_elements: record.dig(sd_field)).to_s if record.dig(sd_field)
        end
        return sd_array.empty? ? '-' : sd_array.join('')
      end
    end
  end
end
