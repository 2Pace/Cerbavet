/**
 * @description       : Class permettant de gérer les messages vers Paytweak
 * @author            : Ingrid Omar
 * @group             :
 * @last modified on  : 02/01/2024
 * @last modified by  : Ingrid Omar
**/

public with sharing class CV_Intf_PaytweakSchemaBuilder {
    
    public static String  getInvoicePayload(blng__Invoice__c invoice, Boolean isPaymentCheck) {
        Decimal amount;
        String cur; // Currency
        String email;
        String order_id;
        String salesforceId;
        String company;
        String lastName;
        String firstName;
        
        // Check If Intf is Paytweak or not 
        String isPaytweak = CV_Intf_Service.getRelatedSObjectFieldValue(invoice,'PAYTWEAK_InterfacePaytweak');
        order_id = CV_Intf_Service.getSObjectFieldValue(invoice,'PAYTWEAK_Invoice_Number');
        System.debug('**** IMA =W> Is paytweak ??? '+isPaytweak + ' / OrderId = ' + order_id + ' / IsPaymentCheck val = ' + isPaymentCheck);

        if(!isPaymentCheck) {
            Items items;
            String invNum = CV_Intf_Service.getSObjectFieldValue(invoice,'PAYTWEAK_Invoice_Number');
            System.debug('**** IMA invoice num == ' + invNum);
            String billTotal = CV_Intf_Service.getSObjectFieldValue(invoice,'PAYTWEAK_Invoice_Amount');
            amount = Decimal.valueOf(billTotal);
            String amountFinal = String.valueOf(amount);
            cur = CV_Intf_Service.getSObjectFieldValue(invoice, 'PAYTWEAK_Invoice_Currency');
            email = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'PAYTWEAK_Invoice_Account_Email');  

            firstname = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'PAYTWEAK_Invoice_Firstname');
            lastname = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'PAYTWEAK_Invoice_Lastname') ;
            

            String invoiceId = CV_Intf_Service.getSObjectFieldValue(invoice, 'PAYTWEAK_Invoice_Id');
            System.debug('**** IMA invoiceId Value = ' + invoiceId);
            items = getAddress(invoice);            
            String itemsJson = JSON.serialize(items);
            System.debug('**** IMA items json value == ' + itemsJson);
            System.debug('**** IMA order_id value = ' + order_id);

            Blob formData = CV_Intf_HttpHexFormBuilder.build()
                .writeParam( 'order_id', order_id )
                .writeParam( 'amount', amountFinal )
                .writeParam( 'cur', cur )
                .writeParam( 'firstname', firstname )
                .writeParam( 'lastname', lastname )
                .writeParam( 'life', '90')
                .writeParam( 'billing_address', String.valueOf(itemsJson) )
                .getFormAsBlob();
            String blobValue = formData.tostring();
            System.debug('**** IMA blobValue blob value == ' + blobValue);
            return blobValue;
        } else if( isPaymentCheck) {
            String link_id  = CV_Intf_Service.getSObjectFieldValue(invoice, 'PAYTWEAK_Invoice_Payment_Order_Id'); 

            Blob formData = CV_Intf_HttpHexFormBuilder.build()
            .writeParam( 'order_id', order_id )
            .writeParam( 'link_id', link_id )
            .getFormAsBlob();
            String blobValue = formData.tostring();
            System.debug('**** IMA blobValue blob isPaymentCheck value == ' + blobValue);
            return blobValue;
        }
        return null;
    }

    private static Items getAddress(blng__Invoice__c invoice){
        Items item = new Items(invoice);
        system.debug('**** IMA itemAddress value == '  + item);
    
        return item;
    }

    public class Items {

        public String address;
        public String additional_information;
        public String zip_code;
        public String city;
        public String country;

        public Items(blng__Invoice__c invoice) {

            this.address = CV_Intf_Service.getRelatedSObjectFieldValue(invoice,'PAYTWEAK_Invoice_Account_Street');
            this.additional_information = '';
            this.city = CV_Intf_Service.getRelatedSObjectFieldValue(invoice,'PAYTWEAK_Invoice_Account_City');
            this.country = CV_Intf_Service.getSObjectFieldValue(invoice, 'PAYTWEAK_InvoiceLine_VAT');
            this.zip_code =  CV_Intf_Service.getRelatedSObjectFieldValue(invoice,'PAYTWEAK_Invoice_Account_ZipCode');

        }
    }

    public class ResponsePaymentOrder {
        public String url;
        public String order_id;
        public String qrcode;
        public String code;
        public String message;
    }

    public class ResponseCheckPaymentOrder {
        public Attributes attributes {get;set;}
        public String code {get;set;}
        public String message {get;set;}
        
    }

    public class BodyError {
        public String code;
        public String message;
    }

    public class Attributes{
        public String id {get; set;}
        public String dateT {get; set;}
        public String name {get; set;}
        public String email {get; set;}
        public String order_id {get; set;}
        public String amount {get; set;}
        public String monthly {get; set;}
        public String link_url {get; set;}
        public String msg_type {get; set;}
        public String phone {get; set;}
        public String subject {get; set;}
        public String message_text {get; set;}
        public String message_html {get; set;}
        public String user {get; set;}
        public String groupT {get; set;}
        public String scenario {get; set;}
        public String freetext {get; set;}
        public String clics {get; set;}
        public String paid {get; set;}
        public String active {get; set;}
    }
}