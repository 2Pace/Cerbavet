/**
 * Created by Michael on 16-10-22.
 */

global class CV_InvoiceNumberDuplicateCheckBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Deduplicate';

    private Datetime runningDate;
    private Map<String, String> lastFacNumberByInvoiceTypes;
    private Set<String> rerunInvoiceTypes;

    public CV_InvoiceNumberDuplicateCheckBatch(Date forcedDate) {

        this.runningDate = (forcedDate == null) ? Date.today() : forcedDate;
        this.lastFacNumberByInvoiceTypes = new Map<String, String>();
        this.rerunInvoiceTypes = new Set<String>();

    }


    global Database.querylocator start(Database.BatchableContext bc) {

        String dateFormatted = runningDate.year() + '-' + String.valueOf(runningDate.month()).leftPad(2, '0') + '-' + String.valueOf(runningDate.day()).leftPad(2, '0');
        String dateStart = dateFormatted + 'T00:00:01.00Z';
        String dateEnd = dateFormatted + 'T23:59:59.00Z';

        String query = 'SELECT Id, blng__InvoiceRunCreatedBy__r.Name, Numero_Facturation_Cerbavet__c ' ;
        query += 'FROM blng__Invoice__c ';
        query += 'WHERE CreatedDate >= ' + dateStart + ' AND CreatedDate <= ' + dateEnd + ' ';
        query += 'ORDER BY Numero_Facturation_Cerbavet__c';

        System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch start query: ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;

    }

    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoices) {

        System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch execute enter lastFacNumberByInvoiceTypes: ' + lastFacNumberByInvoiceTypes);
        System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch execute enter rerunInvoiceTypes: ' + rerunInvoiceTypes);

        for (blng__Invoice__c invoice : invoices) {
            String invoiceType = CV_InvoiceService.getInvoiceType(invoice.blng__InvoiceRunCreatedBy__r.Name);

            if (!lastFacNumberByInvoiceTypes.containsKey(invoiceType)) {
                lastFacNumberByInvoiceTypes.put(invoiceType, invoice.Numero_Facturation_Cerbavet__c);

            } else {
                String previousNum = lastFacNumberByInvoiceTypes.get(invoiceType);
                if (previousNum == invoice.Numero_Facturation_Cerbavet__c) {
                    System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch duplicate : ' + previousNum);
                    rerunInvoiceTypes.add(invoiceType);
                }

                lastFacNumberByInvoiceTypes.put(invoiceType, invoice.Numero_Facturation_Cerbavet__c);
            }
        }

        System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch execute end lastFacNumberByInvoiceTypes: ' + lastFacNumberByInvoiceTypes);
        System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch execute end rerunInvoiceTypes: ' + rerunInvoiceTypes);

    }

    global void finish(Database.BatchableContext bc) {

        System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch finish rerunInvoiceTypes: ' + rerunInvoiceTypes);

        for (String invoiceType : rerunInvoiceTypes) {
            System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch finish invoiceType: ' + invoiceType);
            System.debug('========================== CV_InvoiceNumberDuplicateCheckBatch finish runningDate: ' + runningDate);

            CV_InvoiceService.recaculateNumbering(invoiceType, runningDate);
        }
    }

    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_InvoiceNumberDuplicateCheckBatch batch = new CV_InvoiceNumberDuplicateCheckBatch(null);
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }

    global static String scheduleThis(String schedule) {

        CV_InvoiceNumberDuplicateCheckBatch job = new CV_InvoiceNumberDuplicateCheckBatch(null);
        String batchName = 'CV_InvoiceNumberDuplicateCheckBatch' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }

}