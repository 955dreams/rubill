module Rubill
  class Bill < Base
    def self.send_payment(opts)
      SentPayment.create(opts)
    end

    def self.set_approvers(bill_id, approver_user_id_array)
      Rubill::Query.execute('/SetApprovers.json', entity: 'Bill',
                            objectId: bill_id,
                            approvers: approver_user_id_array)
    end

    def self.approve_bill(bill_id)
      Rubill::Query.execute('/Approve.json', entity: 'Bill', objectId: bill_id)
    end

    def self.pay_bills(pay_bills_object)
      Rubill::Query.execute('/PayBills.json', pay_bills_object)
    end

    def self.remote_class_name
      "Bill"
    end
  end
end
