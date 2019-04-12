# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: fixture.proto

require 'google/protobuf'

require 'google/protobuf/timestamp_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "google.gax.Request" do
    optional :name, :string, 1
    optional :user, :message, 2, "google.gax.User"
  end
  add_message "google.gax.User" do
    optional :name, :string, 1
    optional :type, :enum, 2, "google.gax.User.UserType"
    repeated :posts, :message, 3, "google.gax.Post"
    map :map_field, :string, :string, 4
    optional :bytes_field, :bytes, 5
    optional :timestamp, :message, 6, "google.protobuf.Timestamp"
  end
  add_enum "google.gax.User.UserType" do
    value :UNSPECIFIED, 0
    value :ADMINISTRATOR, 1
  end
  add_message "google.gax.Post" do
    optional :text, :string, 1
  end
  add_message "google.gax.GoodPagedRequest" do
    optional :name, :string, 1
    optional :page_size, :int32, 2
    optional :page_token, :string, 3
  end
  add_message "google.gax.Int64PagedRequest" do
    optional :name, :string, 1
    optional :page_size, :int64, 2
    optional :page_token, :string, 3
  end
  add_message "google.gax.MissingPageTokenRequest" do
    optional :name, :string, 1
    optional :page_size, :int32, 2
  end
  add_message "google.gax.MissingPageSizeRequest" do
    optional :name, :string, 1
    optional :page_token, :string, 3
  end
  add_message "google.gax.GoodPagedResponse" do
    repeated :users, :message, 1, "google.gax.User"
    optional :next_page_token, :string, 2
  end
  add_message "google.gax.MissingRepeatedResponse" do
    optional :user, :message, 1, "google.gax.User"
    optional :next_page_token, :string, 2
  end
  add_message "google.gax.MissingMessageResponse" do
    repeated :names, :string, 1
    optional :next_page_token, :string, 2
  end
  add_message "google.gax.MissingNextPageTokenResponse" do
    repeated :users, :message, 1, "google.gax.User"
  end
  add_message "google.gax.BadMessageOrderResponse" do
    repeated :posts, :message, 2, "google.gax.Post"
    repeated :users, :message, 1, "google.gax.User"
    optional :next_page_token, :string, 3
  end
end

module Google
  module Gax
    Request = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.Request").msgclass
    User = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.User").msgclass
    User::UserType = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.User.UserType").enummodule
    Post = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.Post").msgclass
    GoodPagedRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.GoodPagedRequest").msgclass
    Int64PagedRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.Int64PagedRequest").msgclass
    MissingPageTokenRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.MissingPageTokenRequest").msgclass
    MissingPageSizeRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.MissingPageSizeRequest").msgclass
    GoodPagedResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.GoodPagedResponse").msgclass
    MissingRepeatedResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.MissingRepeatedResponse").msgclass
    MissingMessageResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.MissingMessageResponse").msgclass
    MissingNextPageTokenResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.MissingNextPageTokenResponse").msgclass
    BadMessageOrderResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("google.gax.BadMessageOrderResponse").msgclass
  end
end
