# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
require 'faker'

puts "Fill database with sample data"

100.times do |n|
  title  = "Post number #{n+1}"
  content = Faker::Lorem.sentence(100)
  Post.create!(:title => title,
               :content => content,
               :tags => Faker::Lorem.words(10),
               :comments_counter => 10,
               :created_at => (100-n).days.ago)
end

Post.all.each do |post|
  10.times do |n|
    name = Faker::Name.name
    content = Faker::Lorem.sentence(10)
    cc=post.comments.build(  :content => content,
                          :created_at => n.minutes.ago)
    cc.name = name
    cc.url = "http://www.example.com/#{name.gsub(' ','-')}"
    cc.ip = Array.new(4){rand(256)}.join('.')
    cc.save
  end
end
