class Area < ActiveRecord::Base
  # Associations
  has_many :periods, dependent: :delete_all
end
