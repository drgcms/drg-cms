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
  @by_day = [] 
end

###################################################################
# Collects total number of requests and respond time for calculating
# average response time.
###################################################################
def response_by_days
  i = 0
  selected_files.each do |file_name|
    result = [file_name[0,6], 0, 0]
    File.readlines(file_name).each do |line|
      next unless line.match 'Completed 200 OK in'
      time = $'.split('ms').first.strip.to_i
      result[1] += 1
      result[2] += time
    end
    p result
    @by_day << result
#     break if (i+=1) > 4
  end
end

###################################################################
# Prints links which resultet in 404 error.
###################################################################
def analyze_404
  i = 0
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
p @by_day
c = @by_day.inject('') {|result, e| result << e.join("\t") + "\n"} 
File.open('result.txt','w') {|f| f.write(c) }
