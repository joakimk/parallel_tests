require File.join(File.dirname(__FILE__), 'parallel_tests')

require 'httparty'

class TestbotServer
  include HTTParty
end  

class ParallelTestbot < ParallelTests

  def self.run_tests_with_type(test_files, process_number, type)
    job_id = TestbotServer.post('/jobs', :body => { :root => config.server_path,
                                                    :files => relative_paths(test_files).join(' '),
                                                    :type => type,
                                                    :server_type => config.server_type || 'rsync' })
    results = nil
    loop do
      sleep 1
      results = TestbotServer.get("/jobs/#{job_id}") rescue nil
      break if results != nil
    end
    puts results
    results
  end

  def self.prepare
    return if config.server_type && config.server_type != 'rsync'
    TestbotServer.base_uri(config.server_uri)
    ignores = config.ignores.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
    system "rake testbot:before_request &> /dev/null; rsync -az --delete -e ssh #{ignores} . #{config.server_path.gsub(":user", ENV['USER'])}"
  end
  
  def self.process_count
    TestbotServer.base_uri(config.server_uri)
    
    # When several requesters try to start jobs at the same time, its useful to know how many
    # instances there are in total so that you can use "available_runner_usage" to limit usage for each requester.
    # Because of this we specify last_seen=20.
    available_instances = TestbotServer.get("/runners/available_instances?last_seen=20").to_i
    
    if config.available_runner_usage
      (available_instances * (config.available_runner_usage.to_i / 100.0)).to_i
    else
      available_instances
    end
  end
  
  private
  
  def self.relative_paths(test_files)
    test_files.map { |path| path.gsub(/#{Dir.pwd}\//, '') }
  end
  
  def self.config
    @config ||= OpenStruct.new(YAML.load_file("config/testbot.yml"))
  end  

end