module ActionView::Helpers::PrototypeHelper
  def build_delayed_observer(field_id, options = {})
    build_observer('Form.Element.MediaclueDelayedObserver', field_id, options)
  end
end