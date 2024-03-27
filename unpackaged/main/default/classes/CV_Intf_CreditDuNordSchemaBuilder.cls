/**
 * @description       : Class permetter de gérer les messages vers le Crédit Du Nord
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 21-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_Intf_CreditDuNordSchemaBuilder {

    public class PaymentOrder {

        public Decimal amount;
        public String currencyCode;
        public String orderId;
        public String salesforceId;
        public Boolean isPaymentCheck;
        public String expirationDate;

        public Customer customer;
        public BillindDetails billindDetails;

        public PaymentOrder(blng__Invoice__c invoice, Boolean isPaymentCheck) {

            String billTotal = CV_Intf_Service.getSObjectFieldValue(invoice,'CDN_Invoice_Amount');
            this.amount = Integer.valueOf(Decimal.valueOf(billTotal) * 100);
            this.currencyCode = CV_Intf_Service.getSObjectFieldValue(invoice, 'CDN_Invoice_Currency');
            this.orderId = CV_Intf_Service.getSObjectFieldValue(invoice,'CDN_Invoice_Number');

            customer = new Customer(invoice);
            billindDetails = new BillindDetails(invoice);

            this.salesforceId = CV_Intf_Service.getSObjectFieldValue(invoice, 'CDN_Invoice_Id');
            this.isPaymentCheck = isPaymentCheck;

            Datetime datetimenow = Datetime.now().addDays(90);
            String formatted = datetimenow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            this.expirationDate = formatted;

        }
    }

    public class Customer {

        public String email;
        public String reference;

        public Customer(blng__Invoice__c invoice) {

            this.reference = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_PetName');
            this.email = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_Email');

        }
    }

    public class BillindDetails {

        public String firstName;
        public String lastName;

        public BillindDetails(blng__Invoice__c invoice) {

            this.firstName = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_Firstname');
            this.lastName = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_Lastname');

        }
    }

    public class GetPaymentOrder {

        public String paymentOrderId;
        public String salesforceId;

        public GetPaymentOrder(blng__Invoice__c invoice) {

            this.paymentOrderId = CV_Intf_Service.getSObjectFieldValue(invoice,'CDN_Invoice_Payment_Order_Id');
            this.salesforceId = CV_Intf_Service.getSObjectFieldValue(invoice, 'CDN_Invoice_Id');
        }
    }

    public class ResponsePaymentOrder {

        public String status;
        public String ticket;
        public String mode;

        public ResponseAnswer answer;

    }

    public class ResponseAnswer {

        public String paymentOrderId;
        public String paymentURL;
        public String paymentOrderStatus;
        public String orderId;
        public String errorCode;
        public String errorMessage;
        public String detailedErrorMessage;

    }

}