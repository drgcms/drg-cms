#coding: utf-8
require 'net/smtp'
Rake.application.options.trace = true

##############################################################################
# Add style to message body.
##############################################################################
def get_body(doc)
  style =<<EOT 
<style>
  body {font-family: sans-serif;font-size:12px;}
</style>
EOT
  "#{style}#{doc.body}"
end

###########################################################################
# Actually sends mail to mail server
###########################################################################
def smtp_send(mail)
  smtp = Net::SMTP.start( ActionMailer::Base.smtp_settings[:address] )
  begin
    smtp.send_message mail.to_s, 'pmaster@ozs.si', mail.to
    $mail_sent << mail.to
  rescue Exception => exc
    p "#{mail.to} : #{exc.message}"
    $mail_errors << "#{mail.to} : #{exc.message}\n"
  ensure
    smtp.finish
  end
  sleep 0.4
end
=begin
##############################################################################
# Include pictures as inline attachments and update coresponding links in the message.
##############################################################################
def update_attachments(doc)
  offset = 0
# find img tags 
  while i1 = doc.body.index('<img', offset)
    i2 = doc.body.index('/>', i1) + 1
# find src tag
    s1 = doc.body.index('src="', i1) + 6
    s2 = doc.body.index('"', s1) - 1
    filename = doc.body[s1..s2]
    cid = File.basename(filename)
# read file into inline attachments and replace link with new link
    attachments.inline[cid] = File.read( Rails.root.join('public', filename) )
    doc.body[(s1-1)..s2] = "cid:#{cid}"
#
    offset = i1 + 10 # just in case ..
# replace style with pure html height= and width= because inline style doesn't work in mailers. At least not in outlook.     
    s1 = doc.body.index('style="', i1) + 7
    next if s1.nil? or s1 > i2 # style might not be present
    s2 = doc.body.index('"', s1) - 1
    style = doc.body[s1..s2]
    h_w = ''
    style.split(';').each do |hw|
      a = hw.split(':')
      h_w << "#{a.first}='#{a.last.strip.gsub('px','')}' "
    end
    doc.body[(s1-7)..s2] = h_w
  end
end
=end
##############################################################################
# Include pictures as inline attachments and update coresponding links in the message.
##############################################################################
def update_attachments(docbody, mail)
  offset, n = 0, 0
# find img tags 
  while i1 = docbody.index('<img', offset)
    i2 = docbody.index('/>', i1) + 1
# find src tag
    s1 = docbody.index('src="', i1) + 6
    s2 = docbody.index('"', s1) - 1
    filename = docbody[s1..s2]
    cid = File.basename(filename)
# read file into inline attachments and replace link with new link
    mail.attachments[cid] = File.read( Rails.root.join('public', filename) )
    mail.parts[n].content_id = cid
    mail.parts[n].content_disposition = "inline; filename=#{cid}"

#    attachments.inline[cid] = File.read( Rails.root.join('public', filename) )
    docbody[(s1-1)..s2] = "cid:#{cid}"
    n += 1
#
    offset = i1 + 10 # just in case ..
# replace style with pure html height= and width= because inline style doesn't work in mailers. At least not in outlook.     
    s1 = docbody.index('style="', i1) + 7
    next if s1.nil? or s1 > i2 # style might not be present
    s2 = docbody.index('"', s1) - 1
    style = docbody[s1..s2]
    h_w = ''
    style.split(';').each do |hw|
      a = hw.split(':')
      h_w << "#{a.first}='#{a.last.strip.gsub('px','')}' "
    end
    docbody[(s1-7)..s2] = h_w
  end
end

##############################################################################
# Send document to test e-mail address
##############################################################################
def send_test(doc)
  mail = Mail.new
  mail.to      = doc.to_test
  mail.subject = doc.subject
  mail.from    = doc.from
  update_attachments(doc, mail)
#  
  body = (doc.css.to_s.size > 5 ? "<style type=\"text/css\">#{doc.css}</style>" : '') + doc.body
  html = Mail::Part.new do
    content_type 'text/html; charset=UTF8'
    body body
  end
  mail.html_part = html
  smtp_send(mail)  
end

##############################################################################
# Returns array of addresses mail will be send to.
##############################################################################
def get_adresses(doc)
  a = [] 
# direct specified addresses
  if doc.to_address.size > 5
    doc.to_address.split("\n").each do |line|
      doc.to_address.split(/,|;| /).each { |address| a << [address.strip.downcase] }
    end
  end  
# maling lists    
  doc.to_list.each do |id|
    list = DcMailList.find(id)
    DcMailAddress.where('dc_mail_list_members.dc_mail_list_id' => id, active: true).each do |addr|
      address = ''
      if addr.email.to_s.size > 5
        address = addr.email
      elsif addr.dc_user_id
        address = DcUser.find(addr.dc_user_id).email.to_s
      end
      a << [address.strip.downcase, addr.id] if address.size > 1
    end
  end
# return only unique addresses  
  a.uniq { |s| s.first }
end

##############################################################################
# Send document to defined recipients
##############################################################################
def sending(doc)
  addresses = get_adresses(doc)
  
# Write list of all addresses to file. Very useful when something gets wrong 
  File.open(Rails.root.join('log/sendmail.list'),'w') {|f| f.write(addresses.join("\n")) }
  addresses.each do |a|
    mail = Mail.new
    mail.subject = doc.subject
    mail.from    = doc.from
    docbody      = doc.body.dup
    update_attachments(docbody, mail)
    url = "<a href=\"http://#{doc.dc_site.name}/dc_mail/unsubscribe?id_list=#{a.last}\">#{I18n.t('drgcms.dc_mail.unsubscription')}</a>"
#  
    body = (doc.css.to_s.size > 5 ? "<style type=\"text/css\">#{doc.css}</style>" : '') 
    body << docbody.sub('%{unsubscription}', url)
    part = Mail::Part.new do
      content_type 'text/html; charset=UTF8'
      body body
    end
    mail.html_part = part
    mail.to        = a.first
    smtp_send(mail)  
  end
end

##############################################################################
# Send document to test e-mail address
##############################################################################
def send_report(doc, text, status = :ok)
  mail = Mail.new
  mail.to      = doc.from
  mail.subject = "#{(status == :ok ? '' : I18n.t('drgcms.error'))}#{I18n.t('drgcms.dc_mail.report')}: #{doc.subject}"
  mail.from    = 'SENDMAIL REPORT'
  html = Mail::Part.new do
    content_type 'text/html; charset=UTF8'
    body text.gsub("\n",'<br>')
  end
  smtp_send(mail)  
end

namespace :drg_cms do
namespace :sendmail do
###########################################################################
# sendmail:test
###########################################################################
desc 'Sends mail to test recipient!'

task :test => :environment do
  begin
    id = ENV["MAIL_ID"] || '517a7eb27246cd2958000104'
    doc = DcMail.find(id)
    send_test(doc)
  rescue Exception => exc
    stack = "\n#{Time.now.strftime('%d.%m.%Y %H:%M')}:#{exc.to_s} + \n"
    exc.backtrace.each {|c| stack << "#{c}\n" }
    p stack.to_yaml
    File.open(Rails.root.join('log/error.log'),'a+') {|f| f.write(stack) }
    send_report(doc)
  end      
end
  
###########################################################################
# sendmail:send
###########################################################################
desc 'Sends mail to all recipients!'

task :sending => :environment do
  $mail_errors, $mail_sent = [], []
  ok = false
  begin
    id = ENV["MAIL_ID"] || '517a7eb27246cd2958000104'
    doc = DcMail.find(id)
    if doc.status == 1 # status must be ready
      doc.status = 2; doc.save
      sending(doc)
    else
      send_report(doc, I18n.t('drgcms.dc_mail.message_status_error'), :error )
    end
    ok = true
  rescue Exception => exc
    stack = "ERROR! rake drgcms:sendmail:send\n\n#{Time.now.strftime('%d.%m.%Y %H:%M')}:#{exc.to_s} \n"
    exc.backtrace.each {|c| stack << "#{c}\n\n" }
    stack << "Last OK mail sent:#{$mail_sent.last}\n" 
    p stack.to_yaml
    File.open(Rails.root.join('log/error.log'),'a+') {|f| f.write(stack) }
    send_report(doc, stack, :error )
    doc.status = 3; doc.save
  end
# Send report if OK  
  if ok
    msg  = I18n.t('drgcms.dc_mail.message_sent_to', :number => $mail_sent.size)  + "\n\n"
    msg << I18n.t('drgcms.dc_mail.message_errors', :number => $mail_errors.size) + "\n"
    msg << $mail_errors.join("\n")
    doc.status = 10; doc.save
    send_report(doc, msg)
  end
end
 
end
end

