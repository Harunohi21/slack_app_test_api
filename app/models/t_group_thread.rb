class TGroupThread < ApplicationRecord
  belongs_to :t_group_message
  belongs_to :m_user
  has_many :passive_relationships, class_name:  "TGroupThreadMsgFile",
                                    foreign_key: "groupthreadmsgid",
                                    dependent:   :destroy

end
