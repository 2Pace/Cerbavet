/**
 * @description       : Classe utilisée pour construire le corps du message de facture à envoyer à ECV
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 19-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_Intf_InvoiceSchemaBuilder {

    public String correspondantId;
    public String invoiceType;
    public String recordNumber;
    public String invoiceDate;
    public String invoiceNumber;
    public String currencyCode;
    public String status;
    public String paymentLink;
    public String ownerName;
    public String petName;
    public String breed;
    public String attachment;
    public String salesforceId;

    public Decimal balance;
    public Decimal billTotal;

    public CV_Intf_InvoiceSchemaBuilder(blng__Invoice__c invoice, ContentVersion documentToSend, String dossierId, Boolean isProprio) {

        Boolean isOwner = Boolean.valueOf(CV_Intf_Service.getSObjectFieldValue(invoice,'Invoice_Type'));
        System.debug('===================================== CV_Intf_InvoiceSchemaBuilder isOwner: ' + isOwner);

//        String idDossier = dossierId != null ? dossierId : CV_Intf_Service.getRelatedSObjectFieldValue(invoice,'Invoice_Numero_Dossier');
//        System.debug('===================================== CV_Intf_InvoiceSchemaBuilder idDossier: ' + idDossier);

        String invoiceType = CV_Intf_Service.getTransformationValue(invoice,'Invoice_Type');

        this.correspondantId = CV_Intf_Service.getRelatedSObjectFieldValue(invoice,'Invoice_Correspondant_Id');
        this.invoiceType = invoiceType != null ? invoiceType.toUpperCase() : null;
//        this.recordNumber = idDossier;
        this.recordNumber = isProprio ? CV_Intf_Service.getRelatedSObjectFieldValue(invoice,'Invoice_Numero_Dossier') : null;
        this.invoiceNumber = CV_Intf_Service.getSObjectFieldValue(invoice,'Invoice_Number');
        this.invoiceDate = CV_Intf_Service.getDateStringFormatted(invoice, 'Invoice_Date') + 'T00:01:00Z';
        this.currencyCode = CV_Intf_Service.getSObjectFieldValue(invoice, 'Invoice_Currency');
        this.paymentLink = isOwner ? CV_Intf_Service.getSObjectFieldValue(invoice, 'Invoice_Payment_Link') : null;

        Date currentECVDate = Date.today().addMonths(-1);
        String factureMensuelle = 'Facture Mens. ' + currentECVDate.month() + '-' + currentECVDate.year();
//        this.ownerName = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'Invoice_Owner_Name');
        this.ownerName = isProprio ? CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'Invoice_Owner_Name') : factureMensuelle;

        if (isProprio) {
            this.petName = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'Invoice_Petname');
            this.breed = CV_Intf_Service.getRelatedSObjectFieldValue(invoice, 'Invoice_Breed');
        }

        this.status = CV_Intf_Service.getTransformationValue(invoice, 'Invoice_Status');
        this.salesforceId = CV_Intf_Service.getSObjectFieldValue(invoice, 'Invoice_Id');

        String balance = CV_Intf_Service.getSObjectFieldValue(invoice,'Invoice_Balance');
        System.debug('================================================= CV_Intf_InvoiceSchemaBuilder balance: ' + balance + ' ' + String.isBlank(balance));
        String billTotal = CV_Intf_Service.getSObjectFieldValue(invoice,'Invoice_Total_Amount');
        System.debug('================================================= CV_Intf_InvoiceSchemaBuilder billTotal: ' + billTotal + ' ' + String.isBlank(billTotal));

        this.balance = String.isNotBlank(balance)? Decimal.valueOf(balance) : 0;
        this.billTotal = String.isNotBlank(billTotal) ? Decimal.valueOf(billTotal) : 0;

//        if (isProprio) {
//            this.attachment = documentToSend != null ? EncodingUtil.base64Encode(documentToSend.VersionData) : null;
//        } else {
//            this.attachment = documentToSend != null ? documentToSend.Id : null;
//        }

        this.attachment = documentToSend != null ? EncodingUtil.base64Encode(documentToSend.VersionData) : null;
    }

    public override String toString(){
        return JSON.serialize(this);
    }
}