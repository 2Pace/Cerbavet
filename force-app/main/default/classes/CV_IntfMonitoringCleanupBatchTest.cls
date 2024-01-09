/**
 * Created by Michael on 24-08-22.
 */

@IsTest
private class CV_IntfMonitoringCleanupBatchTest {
    @IsTest
    static void testBehavior() {

        Interface_Monitoring__c interfaceMonitoring = new Interface_Monitoring__c(
                CreatedDate = Datetime.now().addDays(-120),
                Message_Id__c = 'dsmjsdmfjsdmfsjdfmsdjfsmldfj'
        );

        insert interfaceMonitoring;

        Test.startTest();

        CV_IntfMonitoringCleanupBatch batch = new CV_IntfMonitoringCleanupBatch('Interface_Monitoring__c');
        Database.executeBatch(batch);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([SELECT Id FROM Interface_Monitoring__c]);
        System.assertEquals(0, interfaceMonitorings.size());

    }

    @IsTest
    static void testSchedule() {

        System.Test.startTest();

        String sch2 = '0 5 * * * ?';
        String jobId = CV_IntfMonitoringCleanupBatch.scheduleThis(sch2,'Interface_Monitoring__c');

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);
        System.Test.stopTest();

    }
}