require File.join(File.dirname(__FILE__), 'parallel_tests')
require 'httparty'

class TestbotServer
  include HTTParty
end  

# TODO: Extract shared code
class ParallelTestbotCucumber < ParallelTests
  
  def self.run_tests(test_files, process_number)
    job_id = TestbotServer.post('/jobs', :body => { :root => config.server_path,
                                                    :files => relative_paths(test_files).join(' '),
                                                    :type => 'cucumber',
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
    TestbotServer.get("/runners/available_instances").to_i
  end
  
  protected

  # TODO: Spec
  def self.test_result_seperator
    ' '
  end

  # TODO: Spec
  def self.line_is_result?(line)
    line =~ /^\d+ steps/
  end
  
  # TODO: Spec
  def self.line_is_failure?(line)
    line =~ /^\d+ steps.*(\d{2,}|[1-9]) failed/
  end

  def self.find_tests(root)
    Dir["#{root}**/**/*.feature"]
  end
  
  private
  
  def self.relative_paths(test_files)
    test_files.map { |path| path.gsub(/#{Dir.pwd}\//, '') }
  end
  
  def self.config
    @config ||= OpenStruct.new(YAML.load_file("config/testbot.yml"))
  end
  
end
