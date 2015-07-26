
########################################################################
# CarparkRenderer defines methods for rendering Carpark application.
########################################################################
class CarparkRenderer < DcRenderer

########################################################################
# Default method will render application menu.
########################################################################
def default
  @parent.render(partial: 'carpark/menu', formats: [:html])
end
end
