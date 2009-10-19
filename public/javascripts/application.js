// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function open_tag_list (dom_id) {
  try 
  { 
    Effect.SlideDown('tag_link_list_' + dom_id, {duration:0.5}); 
  } catch (e) { 
    alert('RJS error:\n\n' + e.toString()); 
    alert('Effect.SlideDown(\"' + dom_id + '\",{duration:0.5});');
    throw e 
  };
  return false;  
}

function append_link_value(dom_id, value) {
  try 
  { 
    $(dom_id).value = $(dom_id).value + ' ' + value + ' '
  } catch (e) { 
    alert('RJS error:\n\n' + e.toString()); 
    alert('$(\'' + dom_id + '\').value = $(\'' + dom_id + '\').value + \' ' + dom_id + '\'');
    throw e 
  }; 
  return false;
}

