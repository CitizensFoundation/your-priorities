require 'digest/sha1'

FactoryGirl.define do
  factory :user do
    first_name "foobar"
    last_name "dfdsf"
    email "foo@bar.com"
    login "foo"
    password "testpass"
    password_confirmation "testpass"
  end
end
