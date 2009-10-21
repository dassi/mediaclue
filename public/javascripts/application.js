// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function open_tag_list (dom_id) {
  Effect.SlideDown('tag_link_list_' + dom_id, {duration:0.5});
  return false;  
}

function trigger_search_lookahead () {
  Event.fire('search_fulltext', 'mediaclue:search_lookahead');
}

function append_link_value(dom_id, value) {
  var field = $(dom_id);
  field.value = field.value + ' ' + value + ' ';
  trigger_search_lookahead();
  return false;
}

function reset_search_field() {
  $('search_fulltext').value='';
  trigger_search_lookahead();
}

// Spezialisierter Observer (kopiert von Form.Element.DelayedObserver), welcher auch einen Custom-Event benützt
// für das Suchfeld.
Form.Element.MediaclueDelayedObserver = Class.create({
  initialize: function(element, delay, callback) {
    this.delay     = delay || 0.5;
    this.element   = $(element);
    this.callback  = callback;
    this.timer     = null;
    this.lastValue = $F(this.element);
    Event.observe(this.element,'keyup',this.delayedListener.bindAsEventListener(this));
    Event.observe(this.element,'mediaclue:search_lookahead',this.delayedListener.bindAsEventListener(this));
  },
  delayedListener: function(event) {
    if(this.lastValue == $F(this.element)) return;
    if(this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(this.onTimerEvent.bind(this), this.delay * 1000);
    this.lastValue = $F(this.element);
  },
  onTimerEvent: function() {
    this.timer = null;
    this.callback(this.element, $F(this.element));
  }
})