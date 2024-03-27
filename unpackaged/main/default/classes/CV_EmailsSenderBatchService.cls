/**
 * @description       :
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 09-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_EmailsSenderBatchService {

    private static final String DOCUMENT_PAID = 'PAID';
    private static EmailTemplate unpaidEmailTemplate;
    private static EmailTemplate paidEmailTemplate;
    private static Map<String,String> templateMappings;

    public static void loadEmailTemplatesAndMappings(CV_Batch_Settings__mdt batchSettings) {

        templateMappings = new Map<String, String>();

        if (unpaidEmailTemplate == null) {
            List<EmailTemplate> emailsTemplates = new List<EmailTemplate>([SELECT Id, HtmlValue, Body FROM EmailTemplate WHERE Id IN (:batchSettings.Email_Template_Id__c,:batchSettings.Paid_Email_Template_Id__c )]);

            for (EmailTemplate emailTemplate : emailsTemplates) {
                if (emailTemplate.Id == batchSettings.Paid_Email_Template_Id__c) {
                    paidEmailTemplate = emailTemplate;
                } else {
                    unpaidEmailTemplate = emailTemplate;
                }
            }
        }

        for (CV_Email_Template_Mapping__mdt emailTemplateMapping : [SELECT Id, SF_FieldName__c, Template_Tag_Name__c FROM CV_Email_Template_Mapping__mdt WHERE Active__c = TRUE]) {
            templateMappings.put(emailTemplateMapping.Template_Tag_Name__c, emailTemplateMapping.SF_FieldName__c);
        }
    }

    private static String replaceTagsInString(String inputString, blng__Invoice__c invoice) {

        String tmpString = inputString;

        for (String mappingName : templateMappings.keySet()) {

            String value = invoice.get(templateMappings.get(mappingName)) != null ? String.valueOf(invoice.get(templateMappings.get(mappingName))) : ' ';
            tmpString = tmpString.replaceAll(mappingName, value);

        }

        return tmpString;
    }
    
    private static EmailTemplate mergeTemplate(EmailTemplate templateToMerge, blng__Invoice__c invoice) {
        
        EmailTemplate mergedTemplate = templateToMerge.clone();

        mergedTemplate.HtmlValue = replaceTagsInString(templateToMerge.HtmlValue, invoice);
        mergedTemplate.Body = replaceTagsInString(templateToMerge.Body, invoice);
        
        return mergedTemplate;
        
    }

    public static void sendEmail(Map<Id, ContentVersion> contentVersionsByEntityIds, List<blng__Invoice__c> invoices, CV_Batch_Settings__mdt batchSettings, Organization organization, Boolean isClinic) {

        System.debug('========================== CV_EmailsSenderBatchService sendEmail invoices:' + invoices);
        System.debug('========================== CV_EmailsSenderBatchService sendEmail contentVersionsByEntityIds:' + contentVersionsByEntityIds);

        Map<Id, blng__Invoice__c> invoicesInSendingError = new Map<Id, blng__Invoice__c>();
        Map<Id, blng__Invoice__c> invoicesOk = new Map<Id, blng__Invoice__c>();
        Map<Integer, blng__Invoice__c> invoicesByIndex = new Map<Integer, blng__Invoice__c>();

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        Integer index = 0;

        for (blng__Invoice__c invoice : invoices) {
            if ((invoice.blng__Order__r.Email_Patient__c != null && !isClinic)
                    || (invoice.blng__Account__r.Adresse_Email__c != null && isClinic)) {

                List<String> recipients = isClinic ? new List<String>{invoice.blng__Account__r.Adresse_Email__c} : new List<String>{invoice.blng__Order__r.Email_Patient__c};
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

                ContentVersion document = contentVersionsByEntityIds.get(invoice.Id);

                if (document != null) {
                    Boolean isPaid = (invoice.blng__PaymentStatus__c == 'Paid') && !isClinic ? true : false;
                    Boolean isCollege = (invoice.Type_de_Facture__c == 'Cerbavet College') ? true : false;

                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(document.PathOnClient);
                    efa.setBody(document.VersionData);

                    attachments.add(efa);

                    System.debug('========================== CV_EmailsSenderBatchService sendEmail recipients : ' + recipients);

                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

                    EmailTemplate templateToUse = isPaid || isCollege ? paidEmailTemplate : unpaidEmailTemplate;  // Paid template of EMAIL_CLINIC is used for Cerbavet College
                    EmailTemplate mergedTemplate = mergeTemplate(templateToUse, invoice);

                    message.setSaveAsActivity(false);
                    message.setOrgWideEmailAddressId(batchSettings.Default_Sender_Address_Id__c);
                    message.setHtmlBody(mergedTemplate.HtmlValue);
                    message.setPlainTextBody(mergedTemplate.Body);

                    if (isClinic) {
                        String subject = isCollege ? 'Votre facture Mensuelle Cerbavet College' : 'Votre facture mensuelle Cerbavet / ' + invoice.blng__Account__r.Code_compte_metier__c;
                        message.setSubject(subject);

                    } else {
                        message.setSubject('Votre Facture CerbaVet');
                    }

                    if (organization.isSandBox || batchSettings.Overrive_Recipient_Email__c) {
                        System.debug('========================== CV_EmailsSenderBatchService sendEmail OVERRIDE sending !!!!');
                        List<String> recipientOverride = System.Label.CV_Recipients_Override.split(',');
                        System.debug('========================== CV_EmailsSenderBatchService sendEmail recipientOverride: ' + recipientOverride);

                        message.setSubject('Sandbox Overriding sending of : ' + recipients + ' [' + message.getSubject() +']');
                        message.toAddresses = recipientOverride;

                    } else {
                        message.toAddresses = new List<String>(recipients);
                    }
                    System.debug('========================== CV_EmailsSenderBatchService subject: ' + message.getSubject());

                    message.setFileAttachments(attachments);
                    messages.add(message);

                    System.debug('========================== CV_EmailsSenderBatchService sendEmail: ' + message);

                    invoicesByIndex.put(index, invoice);
                    index++;

                } else {
                    invoicesInSendingError.put(invoice.Id, new blng__Invoice__c(Id = invoice.Id, Message_d_erreur__c = 'Pas de PDF généré à envoyer (status ' + invoice.blng__PaymentStatus__c + ')'));
                }
            } else {
                invoicesInSendingError.put(invoice.Id, new blng__Invoice__c(Id = invoice.Id, Message_d_erreur__c = 'Pas d\'email patient spécifié', Erreur_Message__c = true));
            }

        }
        System.debug('========================== CV_EmailsSenderBatchService invoicesByIndex: ' + invoicesByIndex);

        if (!messages.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages, false);

            for (Integer i=0; i < results.size(); i++) {
                Messaging.SendEmailResult ser = results[i];
                blng__Invoice__c invoice = invoicesByIndex.get(i);

                if (ser.isSuccess()) {
                    Boolean isPaid = (invoice.blng__PaymentStatus__c == 'Paid') && !isClinic ? true : false;
                    if (isPaid) {
                        invoice.Document_Facture_Acquittee_Envoye__c = true;
                    } else {
                        invoice.Document_envoye__c = true;
                    }
                    invoice.Message_d_erreur__c = null;
                    invoicesOk.put(invoice.Id, invoice);

                } else {
                    invoice.Message_d_erreur__c = ser.getErrors()[0].getMessage();
                    invoice.Erreur_Message__c = true;
                    invoicesInSendingError.put(invoice.Id, invoice);
                }
            }
        }

        System.debug('========================== CV_EmailsSenderBatchService invoicesInSendingError: ' + invoicesInSendingError);
        if (!invoicesInSendingError.isEmpty()) {
            update invoicesInSendingError.values();
        }

        System.debug('========================== CV_EmailsSenderBatchService invoicesOk: ' + invoicesOk);
        if (!invoicesOk.isEmpty()) {
            update invoicesOk.values();
        }

    }

}