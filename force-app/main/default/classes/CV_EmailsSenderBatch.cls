/**
 * @description       : Batch permettant l'envoi des PDFs au propriétaires'
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 09-06-2022
 * @last modified by  : Michaël Cabaraux
**/

global class CV_EmailsSenderBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Email_Sender';
    private static final String CONFIGURATION_NAME_CLINIC = 'Email_Sender_Clinic';

    private CV_Batch_Settings__mdt batchSettings;
    private Organization orga;
    private Boolean isClinic;

    public CV_EmailsSenderBatch(Boolean isClinic) {

        String configName = isClinic ? CONFIGURATION_NAME_CLINIC : CONFIGURATION_NAME;

        this.batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Sender_Address_Id__c,
                        Email_Template_Id__c, Paid_Email_Template_Id__c, Overrive_Recipient_Email__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :configName
        ];

        this.orga = [SELECT IsSandbox FROM Organization LIMIT 1];
        this.isClinic = isClinic;

    }

    global Database.querylocator start(Database.BatchableContext bc) {

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('blng__Invoice__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' ,blng__Order__r.Email_Patient__c, blng__Account__r.Adresse_Email__c, blng__Account__r.Code_compte_metier__c';
        query += ' FROM blng__Invoice__c';
        query += ' WHERE blng__InvoiceStatus__c = \'Posted\'';
        query += ' AND Erreur_Message__c = false';

        if (!isClinic) {
            query += ' AND ((Document_genere__c = true AND Document_envoye__c = false) OR (Document_Facture_Acquittee__c = true AND Document_Facture_Acquittee_Envoye__c = false))';
            query += ' AND Facture_Proprio__c =  true';

        } else {
            query += ' AND (Document_genere__c = true AND Document_envoye__c = false)';
            query += ' AND Facture_Proprio__c =  false';
        }

//        query += ' AND Id = \'a3Z6N000000GwC3UAK\'';

        System.debug('============================ CV_EmailsSenderBatch start query : ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }

    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoices) {

        CV_EmailsSenderBatchService.loadEmailTemplatesAndMappings(batchSettings);

        Set<Id> invoiceIds = new Set<Id>();
        Map<Id, blng__Invoice__c> invoicesByIds = new Map<Id, blng__Invoice__c>();

        for (blng__Invoice__c invoice : invoices) {
            invoiceIds.add(invoice.Id);
            invoicesByIds.put(invoice.Id, invoice);
        }

        Map<Id, ContentVersion> contentVersionsByEntityIds = CV_PDFManagementService.getPDFsByInvoiceIds(invoiceIds, invoicesByIds, false, isClinic);

        CV_EmailsSenderBatchService.sendEmail(contentVersionsByEntityIds, invoices, this.batchSettings, this.orga, isClinic);

    }

    global void finish(Database.BatchableContext bc) {

        System.debug('============================ CV_EmailsSenderBatch FINISHED');

    }


    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_EmailsSenderBatch batch = new CV_EmailsSenderBatch(isClinic);
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }


    global static String scheduleThis(String schedule, Boolean isClinic) {

        String jobName = isClinic ? 'CV_EmailsSenderBatch_Clinic - ' : 'CV_EmailsSenderBatch_Proprio - ';

        CV_EmailsSenderBatch job = new CV_EmailsSenderBatch(isClinic);
        String batchName = jobName + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }

}