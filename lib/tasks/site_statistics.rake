
#########################################################################
#
#########################################################################
def read_input(message, default='')
  print "#{message} "
  response = STDIN.gets.chomp
  response.blank? ? default : response
 end

########################################################################
#
########################################################################
def create_statistics
  site      = read_input('Enter site name: ')
  @site = DcSite.find_by(name: site)
  return unless @site
  date_from = read_input("Enter from date (yyyymmdd): ")
  return unless date_from.size == 8
  date_to   = read_input("Enter to (yyyymmdd): ")
  return unless date_to.size == 8
#
  @date_from = Time.local(date_from[0,4].to_i, date_from[4,2].to_i, date_from[6,2].to_i).beginning_of_day
  @date_to   = Time.local(date_to[0,4].to_i, date_to[4,2].to_i, date_to[6,2].to_i).end_of_day
#
=begin
  map = 
%Q{
  function() {
    day_session = Date.UTC(this.time.getFullYear(), this.time.getMonth(), this.time.getDate()) + this.session_id;
    day_session = this.time.getFullYear().toString() + this.time.getMonth().toString() + this.time.getDate().toString() + '_' + this.session_id;
    emit({day_session: day_session}, {count: 1});
  }
}  
reduce = 
%Q{
  function(key, values) {
    var count = 0;
    values.forEach(function(v) {
      count += v['count'];
    });
  }
}  
  visits = DcVisit.only(:session_id, :time).where(:time.gt => @date_from, :time.lt => @date_to).map_reduce(map, reduce).out(inline: 1).to_a
  visits.each do |stat|
    p stat
  end
=end
  p 'Reading visits collection ...'
  totals    = {}
  totals_ip = {}
  visits = DcVisit.only(:session_id, :time,:ip).where(:time.gt => @date_from, :time.lt => @date_to).order_by('time asc')
  visits.each do |visit|
    key = visit.time.strftime('%Y%m%d') + '_' + visit.session_id.to_s
    totals[key] ||= 0
    totals[key] += 1

    key = visit.time.strftime('%Y%m%d') + '_' + visit.ip.to_s
    totals_ip[key] ||= 0
    totals_ip[key] += 1
  end
  p 'Calculating totals ....'
# Totals by unique
  date_totals = {}
  totals.each do |total|
    date = total.first[0,8]
    date_totals[date] ||= [0,0,0]
    date_totals[date][0] += total.last
    date_totals[date][1] += 1
  end
# Totals by ip
  totals_ip.each do |total|
    date = total.first[0,8]
    date_totals[date][2] += 1
  end
# Create output file  
  p 'Creating output ....'
  output = "date\tunique\tunique_by_ip\tvisits\n"
  old_date,unique,count = 0,0
  date_totals.to_a.sort! {|x,y| x <=> y}.each do |e|
    output << [e.first, e.last[1], e.last[2], e.last[0] ].join("\t") + "\n"
  end
  filename = Rails.root.join('tmp/','statistics.txt')
  File.open(filename,'w') {|f| f.write(output) }
  p "Statistics saved to #{filename}."
end  


#########################################################################
#
#########################################################################
namespace :drg_cms do
  desc "Quick site statistics according to dc_visits collection."
  task :site_statistics => :environment do
    create_statistics
  end
end