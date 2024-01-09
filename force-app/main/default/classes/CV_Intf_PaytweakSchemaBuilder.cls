/**
 * @description       : Class permettant de gérer les messages vers le Paytweak
 * @author            : Ingrid Omar
 * @group             :
 * @last modified on  : 02/01/2024
 * @last modified by  : Ingrid Omar
**/

public with sharing class CV_Intf_PaytweakSchemaBuilder extends CV_Intf_PaytweakJSONSchemBuilder {

    public class PaymentOrder {

        public Decimal amount;
        public String address_customer;
        public String city;
        public String cur; // Currency
        public String email;
        public String phone;
        public String reference; //Votre Numéro de facture
        public String zip;
        public String date; //Date de création de la facture
        public String due; // Date échéance facture
        public String order_id;
        public String salesforceId;
        public Boolean isPaymentCheck;
        public String expirationDate;
        public String company;

        public Items items;

        public PaymentOrder(blng__Invoice__c invoice, Boolean isPaymentCheck) {

            String billTotal = CV_Intf_Service.getSObjectFieldValue(invoice,'CDN_Invoice_Amount');
            this.amount = Integer.valueOf(Decimal.valueOf(billTotal) * 100);
            this.cur = CV_Intf_Service.getSObjectFieldValue(invoice, 'CDN_Invoice_Currency');
            this.reference = CV_Intf_Service.getSObjectFieldValue(invoice,'CDN_Invoice_Number');

            customer = new Customer(invoice);

            this.order_id = CV_Intf_Service.getSObjectFieldValue(invoice, 'CDN_Invoice_Id');
            this.isPaymentCheck = isPaymentCheck;

            Datetime datetimenow = Datetime.now().addDays(90);
            String formatted = datetimenow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            this.expirationDate = formatted;

        }
    }

    public class Items {

        public String vat;
        public String desc;
        public String ref;
        public String quantity;
        public String price;

        public Customer(blng__Invoice__c invoice) {

            this.ref = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_PetName');
            this.desc = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_PetName');
            this.quantity = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_PetName');
            this.ref = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_PetName');
            this.vat = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_Email');
            this.price = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_Email');

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