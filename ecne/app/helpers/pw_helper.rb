module PwHelper

  def length_tag(name, min, max, default = false)
    opts = ""
    min.upto(max) { |x| opts += "<option #{x == default ? "selected" : ""}>#{x}</option>" }
    if default
      select_tag name, opts
    else
      select_tag name, opts
    end
  end

  def add_tag_image_link
    image_tag "Crystal_Clear_action_edit_add", :size => "16x16"
  end

  def del_tag_image_link
    image_tag "Crystal_Clear_action_button_cancel", :size => "16x16"
  end

  def prev_image_link
    image_tag "Crystal_Clear_action_2leftarrow", :size => "32x32"
  end

  def next_image_link
    image_tag "Crystal_Clear_action_2rightarrow", :size => "32x32"
  end

end
