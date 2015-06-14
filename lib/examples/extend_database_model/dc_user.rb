require_dependency DrgCms.model 'dc_user'

class DcUser
include DcUserConcern
 
field :member,      type: Boolean,  default: false
field :card_number, type: String

index( { 'card_number' => 1 } )

validate :my_control

def my_control
  if member and card_number.to_s.size < 8
    errors.add(:card_number, "Card number is not valid!")
  end
end

end