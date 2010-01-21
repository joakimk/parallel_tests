require File.join(File.dirname(__FILE__), 'parallel_tests')
require 'httparty'

class TestbotServer
  include HTTParty
end  

class ParallelTestbotSpecs < ParallelTests
  
  def self.run_tests(test_files, process_number)
    TestbotServer.base_uri(config.server_uri)
    job_id = TestbotServer.post('/jobs', :body => { :root => config.server_path,
                                                    :files => test_files.join(' ') })
    results = nil
    loop do
      sleep 1
      results = TestbotServer.get("/jobs/#{job_id}") rescue nil
      break if results
    end
    results
  end
  
  def self.prepare
    ignores = config.ignores.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
    system "rsync -az --delete -e ssh #{ignores} . #{config.server_path.gsub(":user", ENV['USER'])}"
  end
  
  private
  
  def self.load_config
    @config ||= OpenStruct.new(YAML.load_file("config/testbot.yml"))
  end
  
end
