#!/usr/bin/env ruby
gem 'mysql2', '~> 0.3.18'
require 'net/http'
require 'mysql2'
require 'json'

module ToLog
  def to_log(data)
    string = Time.now.strftime("%H:%M:%S %d.%m.%y ").to_s + data.to_s + "\n"
    File.open(@log_path, 'a') { |f| f.write(string) }
  end
end

class Daemon

  def initialize(data)
    @client = data[:client] # MySQL
    @log_path = data[:log_path] # Log
    @connection_id = data[:connection_id]
    @controller_identifier = data[:controller_identifier]
    @login = data[:login] # Controller
    @password = data[:password] # Controller
    @frequency = data[:frequency] # For daemon
    @table_name = data[:table_name] # Input table
    @log_table_name = data[:log_table_name] # Events log table
    # Connections log table
    @connections_log_table_name = data[:connections_log_table_name]

    # Catch exit signal
    Signal.trap("TERM") do
      to_log("Exit: PID #{Process.pid}")
      exit
    end
  end

  extend ToLog

  def get_data(login, password, command)
    begin
      uri = URI("https://ccu.sh/data.cgx?cmd=#{command}")
      response = Net::HTTP.start(uri.hostname, uri.port,
                                               use_ssl: true) do |http|
        req = Net::HTTP::Get.new(uri)
        req.basic_auth login, password
        http.read_timeout = 15
        http.request(req)
      end
      message = response.body
      { json: JSON.parse(message), raw_data: message }
    rescue

      # Write in connections log
      begin
        to_connections_log("HTTP error")
      rescue
        to_log("Can't write in log that connection to controller is lost")
      end

      to_log("Error: HTTP")
      'nope'
    end
  end

  def insert_data(data, message)

    # Prepare data
    values = [
      created_at = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'),
      updated_at = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'),
      connection_id = @connection_id,
      controller_identifier = @controller_identifier,
      voltage_1 = data["Inputs"][0]["Voltage"],
      state_1 = data["Inputs"][0]["Active"],
      voltage_2 = data["Inputs"][1]["Voltage"],
      state_2 = data["Inputs"][1]["Active"],
      voltage_3 = data["Inputs"][2]["Voltage"],
      state_3 = data["Inputs"][2]["Active"],
      voltage_4 = data["Inputs"][3]["Voltage"],
      state_4 = data["Inputs"][3]["Active"],
      voltage_5 = data["Inputs"][4]["Voltage"],
      state_5 = data["Inputs"][4]["Active"],
      voltage_6 = data["Inputs"][5]["Voltage"],
      state_6 = data["Inputs"][5]["Active"],
      voltage_7 = data["Inputs"][6]["Voltage"],
      state_7 = data["Inputs"][6]["Active"],
      voltage_8 = data["Inputs"][7]["Voltage"],
      state_8 = data["Inputs"][7]["Active"],
      voltage_9 = data["Inputs"][8]["Voltage"],
      state_9 = data["Inputs"][8]["Active"],
      voltage_10 = data["Inputs"][9]["Voltage"],
      state_10 = data["Inputs"][9]["Active"],
      voltage_11 = data["Inputs"][10]["Voltage"],
      state_11 = data["Inputs"][10]["Active"],
      voltage_12 = data["Inputs"][11]["Voltage"],
      state_12 = data["Inputs"][11]["Active"],
      voltage_13 = data["Inputs"][12]["Voltage"],
      state_13 = data["Inputs"][12]["Active"],
      voltage_14 = data["Inputs"][13]["Voltage"],
      state_14 = data["Inputs"][13]["Active"],
      voltage_15 = data["Inputs"][14]["Voltage"],
      state_15 = data["Inputs"][14]["Active"],
      voltage_16 = data["Inputs"][15]["Voltage"],
      state_16 = data["Inputs"][15]["Active"],
      output_1 = data["Outputs"][0],
      output_2 = data["Outputs"][1],
      output_3 = data["Outputs"][2],
      output_4 = data["Outputs"][3],
      output_5 = data["Outputs"][4],
      output_6 = data["Outputs"][5],
      output_7 = data["Outputs"][6],
      profile = data["Case"],
      temp = data["Temp"],
      power = data["Power"],
      partition_1 = data["Partitions"][0],
      partition_2 = data["Partitions"][1],
      partition_3 = data["Partitions"][2],
      partition_4 = data["Partitions"][3],
      battery_state = data["Battery"]["State"],
      balance = data["Balance"],
      full_message = message
    ]

    columns = [
      "created_at",
      "updated_at",
      "connection_id",
      "controller_identifier",
      "voltage_1", "state_1",
      "voltage_2", "state_2",
      "voltage_3", "state_3",
      "voltage_4", "state_4",
      "voltage_5", "state_5",
      "voltage_6", "state_6",
      "voltage_7", "state_7",
      "voltage_8", "state_8",
      "voltage_9", "state_9",
      "voltage_10", "state_10",
      "voltage_11", "state_11",
      "voltage_12", "state_12",
      "voltage_13", "state_13",
      "voltage_14", "state_14",
      "voltage_15", "state_15",
      "voltage_16", "state_16",
      "output_1",
      "output_2",
      "output_3",
      "output_4",
      "output_5",
      "output_6",
      "output_7",
      "profile",
      "temp",
      "power",
      "partition_1",
      "partition_2",
      "partition_3",
      "partition_4",
      "battery_state",
      "balance",
      "full_message"
    ].join(", ")

    # Set data
    escaped_values = "'" + values.map{ |v| @client.escape(v.to_s) }
                                 .join("', '") + "'"
    command = "INSERT INTO #{@table_name} (#{columns}) "\
                      "VALUES (#{escaped_values})"
    set_data = @client.query(command)
  end

  def to_events(event_type, description, event_id)
    array_of_columns = [
      "created_at",
      "updated_at",
      "event_id",
      "connection_id",
      "controller_identifier",
      "event_type",
      "description"
    ]

    values = [
      created_at = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'),
      updated_at = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'),
      event_id,
      @connection_id,
      @controller_identifier,
      event_type,
      description.to_json
    ]

    columns = array_of_columns.join(", ")

    escaped_values = "'" + values.map{ |v| @client.escape(v.to_s) }
                                 .join("', '") + "'"

    command = "INSERT INTO #{@log_table_name} (#{columns}) "\
                      "VALUES (#{escaped_values})"
    set_data = @client.query(command)
  end

  def to_connections_log(message)
    array_of_columns = [
      "created_at",
      "updated_at",
      "connection_id",
      "controller_identifier",
      "message"
    ]

    values = [
      created_at = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'),
      updated_at = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'),
      @connection_id,
      @controller_identifier,
      message
    ]

    columns = array_of_columns.join(", ")

    escaped_values = "'" + values.map{ |v| @client.escape(v.to_s) }
                                 .join("', '") + "'"

    command = "INSERT INTO #{@connections_log_table_name} (#{columns}) "\
                     "VALUES (#{escaped_values})"
    set_data = @client.query(command)
  end

  def parse_events(data)

    # Check if events exist
    if data["Events"].is_a?(Array)

      # Sort events by ID
      events = data["Events"].sort_by { |h| h['ID'] }

      # Log events
      events.each do |e|

        # Check if record exists
        event_type = @client.escape(e['Type'].to_s)
        description = @client.escape(e.to_json.to_s)
        command = "SELECT * FROM #{@log_table_name} "\
                  "WHERE event_type='#{event_type}' "\
                  "AND description='#{description}' "\
                  "ORDER BY created_at DESC LIMIT 1"
        record = @client.query(command)

        # Log if record with such ID doesn't exist in database
        if record.count == 0 || record.first.fetch('event_id') != e['ID']
          log_answer = to_events(e['Type'], e, e['ID'])
        end
      end
    end
  end

  def data_valid?(data)
     data != 'nope' && data.is_a?(Hash) &&
     (["Inputs","Outputs"].all? { |key| data.has_key? key }) &&
     data["Inputs"].is_a?(Array) && data["Outputs"].is_a?(Array) &&
     data["Inputs"].length == 16 && data["Outputs"].length == 7
  end

  #---------------------------- Main programm ----------------------------------

  def start_collecting
    loop do

      # Get data
      data = get_data(@login, @password, '{"Command":"GetStateAndEvents"}')

      # Check for errors
      if @client != 'nope' && data != 'nope' && data_valid?(data[:json])

        begin
          insert_data(data[:json], data[:raw_data])
        rescue
          to_log("Error: Can't insert data to database to #{@table_name}")
        end

        begin
          parse_events(data[:json])
        rescue
          to_log("Error: Can't insert data to database to #{@log_table_name}")
        end

      else
        to_log("Error: Can't get data")
      end

      to_log("OK: Go to sleep #{@frequency} sec")

      sleep @frequency
    end
  end
end

#---------------------------- Connect to MySql ---------------------------------
def connect_to_db(host, username, password, database)
  begin
    client = Mysql2::Client.new(host: host, username: username,
                                             password: password,
                                             database: database)
  rescue
    client = "nope"
    to_log("Error: Database")
  end
  return client
end

#-------------------------------- Credentials ----------------------------------
include ToLog

# Sleep time
@sleep_time = 5

# Logs
logs_path = ARGV[0].to_s
@log_path = logs_path + "MainProgramm.log"
@errors_log = logs_path + "Errors.log"
$stdout.reopen(@log_path, "a")
$stdout.sync = true
$stderr.reopen(@errors_log, "a")

# MySQL
@host = "localhost"
@username = ENV['DATA_BASE_LOGIN']
@password = ENV['DATA_BASE_PASSWORD']
@database = "center_database"
@table_name = "records"
@log_table_name = "logs"
@connections_log_table_name = "connection_logs"
@connection_table = "connections"

#------------------------------- Main Program ----------------------------------

# Log main program PID
to_log("Main program PID: #{Process.pid}")

# Connect to MySql
client = connect_to_db(@host, @username, @password, @database)

# Initialise variables
@first_start = true
@pids = []

loop do

  # Initialise variables
  @new_processes = []
  @for_destroy = @pids.clone

  # Select all connections
  records = client.query("SELECT * FROM #{@connection_table}") rescue 'nope'

  # Check if the program is started for the first time
  # Check if no SQL errors
  # Check if records exist in database
  if !(@first_start || records == 'nope' || records.nil?)

    # Select connections for update
    records.each(as: :hash) do |r|
      if r['update_me'] == 1
        @new_processes << r

        # Remove 'update me' flag
        begin
          command = "UPDATE #{@connection_table} SET update_me = 0 " +
                    "WHERE id = #{r['id']}"
          client.query(command)
        rescue
          to_log("SQL: 'update_me' field wasn't updated")
        end
      else
        # Remove all connections from list "for destroy"
        # if they exist in the database and don't have mark 'update me'
        @for_destroy.delete_if { |x| x[:connection_id] == r['id'] }
      end
    end

    @for_destroy.each do |p|
      begin
        # Kill process
        Process.kill("TERM", p[:pid])
        Process.wait p[:pid]

        # Forget this PID
        @pids.delete_if { |x| x[:pid] == p[:pid] }

        to_log("Daemon #{p[:controller_identifier]} " +
               "PID: #{p[:pid]} was killed")
      rescue
        to_log("Error: process with PID #{p[:pid]} wasn't killed")
      end
    end
  elsif @first_start && !(records == 'nope' || records.nil?)

    # Undo first time
    @first_start = false

    # Select all connections
    @new_processes = records

  elsif records == nil
    to_log("SQL: return nil")
  end

  # Launch new processes
  @new_processes.each do |r|
    begin
      pid = Process.fork do

        # Credentials for daemons
        data = {
          login: r['login'],
          password: r['password'],
          client: client,
          frequency: r['frequency'],
          table_name: @table_name,
          log_table_name: @log_table_name,
          connections_log_table_name: @connections_log_table_name,
          connection_id: r['id'],
          controller_identifier: r['identifier'],
          log_path: logs_path + r['identifier'] + ".log"
        }

        # Create daemon
        daemon = Daemon.new(data)
        daemon.start_collecting
      end

      # Store PID
      @pids << { pid: pid, connection_id: r['id'],
                 controller_identifier: r['identifier'] }
      to_log("Daemon #{r['identifier']} PID: #{pid} was created")
    rescue
      to_log("Error while Daemon was creating")
    end
  end

  # Wait some time
  to_log("OK: Go to sleep #{@sleep_time} sec")
  sleep @sleep_time
end
