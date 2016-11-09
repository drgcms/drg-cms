#--
# Copyright (c) 2012+ Damjan Rems
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

########################################################################
# Task in this file are intend for cleaning up and making archive of statistics collections.
# 
# rake drg_cms:clear_sessions. This is just an example how to cleanup sessions collection.
# 
# rake clear_visits. Will archive and delete dc_visits documents. You will be prompted to enter end_date.
# 
# rake drg_cms:clear_ad_stats. Will archive and delete dc_ad_stats collection. You will be prompted to enter end_date.
########################################################################

namespace :drg_cms do
  desc 'Clears mongodb session collection.'
  task :clear_sessions, [:name] => :environment do |t, args|
    p 'This is just an example how to clear sessions collection. It wont do anything because of next line.'
    return if true
# This should remove all sessions documents created by robots
# It is quite a task to compare two dates in mongoid. This should not be problem if it is run daily
    ActionDispatch::Session::MongoidStore::Session.all.each do |doc|
      doc.delete if (doc.created_at == doc.updated_at or doc.updated_at < 100.days.ago)
    end
# or if you want to clear everything older than 1 week    
    ActionDispatch::Session::MongoidStore::Session.where(:updated_at.lt => 1.week.ago).delete
    DcSite.collection.database.command(eval: "db.runCommand ( { compact: 'sessions' } )" )
  end

###########################################################################
  desc 'Clears mongodb session documents created by web robots'
  task :clear_sessions_from_robots, [:name] => :environment do |t, args|
# This should remove all sessions documents created by web robots
    ActionDispatch::Session::MongoidStore::Session.all.each do |doc|
      doc.delete if (doc.created_at == doc.updated_at)
    end
    DcSite.collection.database.command(eval: "db.runCommand ( { compact: 'sessions' } )" )
  end

###########################################################################
  desc 'Removes all statistics from dc_visits up to specified date and save them to visits_date.json.'
  task :clear_visits, [:name] => :environment do |t, args|
    date = read_input("Enter end date (yyyymmdd): ")
    return unless date.size == 8
    
    archive_file = "visits_#{date}.json"
    return (p "#{archive_file} exists") if File.exist?(archive_file)

    date_to = Time.local(date[0,4].to_i, date[4,2].to_i, date[6,2].to_i).beginning_of_day
    n = 0
    save = ''
    DcVisit.where(:time.lt => date_to).each do |visit|
      save << visit.to_json + "\n"
#      visit.delete
      p "Deleted #{n}" if (n+=1)%10000 == 0
    end
    DcVisit.where(:time.lt => date_to).delete
    File.open(archive_file,'w') {|f| f.write(save)}
    DcSite.collection.database.command(eval: "db.runCommand ( { compact: 'dc_visits' } )" )
  end

###########################################################################
  desc "Removes all statistics of not active ads and save them to ads_#{Time.now.strftime('%Y%d%m')}.json."
  task :clear_ad_stats, [:name] => :environment do |t, args|
    input = read_input("Just press Enter to start. If you type in anything process won't start.")
    return unless input.to_s.size == 0
    today = Time.now.beginning_of_day
    n = 0
    save_stat, save_ads = '', ''
    DcAd.all.each do |ad|
      if !ad.active or (ad.valid_to and ad.valid_to < today)
        save_ads << ad.to_json + "\n"
        DcAdStat.where(:dc_ad_id => ad._id).each do |stat|
          save_stat << stat.to_json + "\n"
          p "Deleted #{n}" if (n+=1)%10000 == 0
        end        
        DcAdStat.where(:dc_ad_id => ad._id).delete
      end
    end
    File.open("ads_stat_#{Time.now.strftime('%Y%d%m')}.json",'w') {|f| f.write(save_stat)}
    File.open("ads_#{Time.now.strftime('%Y%d%m')}.json",'w') {|f| f.write(save_ads)}
    DcSite.collection.database.command(eval: "db.runCommand ( { compact: 'dc_ad_stats' } )" )
  end
  
=begin  
###########################################################################
  desc "Correct error when ad_id ield is used instead of dc_ad_id."
  task :repair_ad_stats, [:name] => :environment do |t, args|
    input = read_input("Just press Enter to start. If you type in anything process won't start.")
    return unless input.to_s.size == 0
    n = 0
    p DcAdStat.only(:id).where(:dc_ad_id => nil).to_a.size
    DcAdStat.where(:dc_ad_id => nil).each do |stat|
      stat.dc_ad_id = stat.ad_id
      stat.ad_id = nil
      stat.save
      
      p n if (n+=1)%1000 == 0
    end
  end
=end
  
end
