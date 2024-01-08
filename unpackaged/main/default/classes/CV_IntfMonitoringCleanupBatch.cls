/**
 * Created by Michael on 24-08-22.
 */

global class CV_IntfMonitoringCleanupBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Intf_Monitoring_Cleanup';
    private Decimal deleted = 0;

    private CV_Batch_Settings__mdt batchSettings;
    private String objectToClean;

    public CV_IntfMonitoringCleanupBatch(String objectToClean) {
        this.objectToClean = objectToClean;
    }

    global Database.querylocator start(Database.BatchableContext bc) {

        this.batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Sender_Address_Id__c, Retention_Period__c,
                        Email_Template_Id__c, Paid_Email_Template_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        Integer frequency = Integer.valueOf(batchSettings.Retention_Period__c) * -1;
        Date deleteWindowDate = Date.today().addDays(frequency);

        System.debug('===================================== CV_IntfMonitoringCleanupBatch deleteWindowDate: ' + deleteWindowDate);

        String query = 'SELECT Id FROM ' + objectToClean + ' WHERE CreatedDate <= :deleteWindowDate';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        System.debug('===================================== CV_IntfMonitoringCleanupBatch toDelete#: ' + scope.size());
        deleted += scope.size();

        delete scope;

    }

    global void finish(Database.BatchableContext bc) {

        System.debug('===================================== CV_IntfMonitoringCleanupBatch deleted#: ' + deleted);

    }

    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_IntfMonitoringCleanupBatch batch = new CV_IntfMonitoringCleanupBatch(objectToClean);
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }


    global static String scheduleThis(String schedule, String objectToClean) {

        CV_IntfMonitoringCleanupBatch job = new CV_IntfMonitoringCleanupBatch(objectToClean);
        String batchName = 'CV_IntfMonitoringCleanupBatch - ' + objectToClean + ' - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }
}