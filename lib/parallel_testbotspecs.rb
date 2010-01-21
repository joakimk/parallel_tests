require File.join(File.dirname(__FILE__), 'parallel_tests')
require 'httparty'

class TestbotServer
  include HTTParty
end  

class ParallelTestbotspecs < ParallelTests
  
  def self.run_tests(test_files, process_number)
    job_id = TestbotServer.post('/jobs', :body => { :root => config.server_path,
                                                    :files => relative_paths(test_files).join(' ') })
    results = nil
    loop do
      sleep 1
      results = TestbotServer.get("/jobs/#{job_id}") rescue nil
      break if results != nil
    end
    puts results
  end
  
  def self.prepare
    TestbotServer.base_uri(config.server_uri)
    ignores = config.ignores.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
    system "rsync -az --delete -e ssh #{ignores} . #{config.server_path.gsub(":user", ENV['USER'])}"
  end
  
  protected

  def self.find_tests(root)
    Dir["#{root}**/**/*_spec.rb"]
  end
  
  private
  
  def self.relative_paths(test_files)
    test_files.map { |path| path.gsub(/#{Dir.pwd}\//, '') }
  end
  
  def self.config
    @config ||= OpenStruct.new(YAML.load_file("config/testbot.yml"))
  end
  
end
