##################################################################
# Short and quick log statistics
##################################################################


##################################################################
# Return list of selected files.
##################################################################
def selected_files
  Dir["#{ARGV.first}*.log"] 
end

###################################################################
# Init some internal vars
###################################################################
def init
  @by_day = {}
  if File.exist?('result.txt')
    File.readlines('result.txt').each do |line|
      a = line.chomp.split("\t")
      @by_day[a.first] = a
    end
  end  
end

###################################################################
# Collects total number of requests and respond time for calculating
# average response time.
###################################################################
def response_by_days
  selected_files.each do |file_name|
    key = file_name[0,6]
    next if @by_day[key]
    result = [key, 0, 0, 0]
    File.readlines(file_name).each do |line|
      next unless line.match 'Completed 200 OK in'
      time = $'.split('ms').first.strip.to_i
      result[1] += 1
      result[2] += time
    end
# average    
    result[3] += result[2]/result[1]
    p result
    @by_day[key] = result
  end
end

###################################################################
# Prints links which resultet in 404 error.
###################################################################
def analyze_404
  selected_files.each do |file_name|
    result = [file_name[0,6], 0, 0]
    url = ''
    File.readlines(file_name).each do |line|
      if m = /Started(.*?)for/.match(line)
        url = m[1]
      end
      if m = /404/.match(line)
        p url.gsub('"','')
      end
    end
  end
end

#analyze_404
#exit 0

init
response_by_days
c = @by_day.inject('') {|result, e| result << e.last.join("\t") + "\n"} 
File.open('result.txt','w') {|f| f.write(c) }
