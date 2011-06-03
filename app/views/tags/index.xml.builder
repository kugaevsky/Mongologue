xml.instruct! :xml, :version => "1.0", :standalone => "yes"
  xml.listdata @tags.map(&:id).join("|")