class TDirectMessage < ApplicationRecord
   belongs_to :send_user, class_name: "MUser", foreign_key: "send_user_id"
  has_many :passive_relationships, class_name:  "TDirectMessageFile",
                                    foreign_key: "diirectmsgid",
                                    dependent:   :destroy
end
