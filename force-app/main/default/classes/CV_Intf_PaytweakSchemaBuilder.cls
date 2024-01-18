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

            firstname = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_Firstname');
            lastname = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'CDN_Invoice_Lastname') ;
            

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
            System.debug('**** IMA blobValue blob value == ' + blobValue);
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
        public String id;
        public String name;
        public String email;
        public String order_id;
        public String amount;
        public String monthly;
        public String link_url;
        public String msg_type;
        public String phone;
        public String subject;
        public String message_text;
        public String message_html;
        public String user;
        public String freetext;
        public String clics;
        public String paid;
        public String active;
    }

    public class BodyError {
        public String code;
        public String message;
    }
}