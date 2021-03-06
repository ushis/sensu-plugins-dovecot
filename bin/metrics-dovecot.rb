#!/usr/bin/env ruby
#
# metics-dovecot
#
# DESCRIPTION:
#   Fetch metrics from Dovecot's stats api
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'

class DovecotMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'host to connect to',
         default: '127.0.0.1'

  option :port,
         short: '-p PORT',
         long: '--port PORT',
         description: 'port to connect to',
         proc: proc(&:to_i),
         default: '24242'

  option :scheme,
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         description: 'metric naming scheme',
         default: "#{Socket.gethostname}.dovecot"

  def run
    sock = TCPSocket.new(config[:host], config[:port])
    sock.write("EXPORT\tglobal\n")
    header = sock.gets.chomp.split
    values = sock.gets.chomp.split
    sock.close

    metrics = header.zip(values).to_h

    # remove reset_timestamp
    metrics.delete('reset_timestamp')

    # set timestamp from last_update
    timestamp = metrics.delete('last_update').to_i

    # output everything
    metrics.each do |key, value|
      output "#{config[:scheme]}.#{key}", value, timestamp
    end

    ok
  end
end
