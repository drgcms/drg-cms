class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  field   :title,       type: String
  field   :body,        type: String
  field   :time_begin,  type: DateTime
  field   :duration,    type: Integer
  field   :search,      type: String
  
  field   :user_id,     type: BSON::ObjectId
  
  index   user_id: 1
   
  validates :title,      presence: true
  validates :time_begin, presence: true
  validates :duration,   presence: true  
  
  before_save :do_before_save
  
#############################################################################
# Before save remove all html tags from body field and save data into search field.
#############################################################################
def do_before_save
  text = ActionView::Base.full_sanitizer.sanitize(self.body, :tags=>[]).to_s
  text.gsub!(/\,|\.|\)|\(|\:|\;|\?/,'')
  text.gsub!('&#13;',' ')
  text.gsub!('&gt;',' ')
  text.gsub!('&lt;',' ')
  text.squish!
  
  self.search = UnicodeUtils.downcase(self.title + text)
end  
  
end
