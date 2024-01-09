/**
 * Created by Michael on 24-08-22.
 */

@IsTest
private class CV_OrderForceTaxRecalcTest {

    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{normalProduct}, pricebook2);

        SBQQ.TriggerControl.disable();

        Order orderNew = new Order(
                AccountId = account.Id,
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebook2.Id,
                Status = 'Draft',
                blng__BillingDayOfMonth__c = '1',
                SBQQ__PaymentTerm__c = 'Net 30',
                blng__InvoiceBatch__c = 'Cerbavet Analysis'
        );
        insert orderNew;

        OrderItem orderItem = new OrderItem(
                OrderId = orderNew.Id,
                Product2Id = normalProduct.Id,
                UnitPrice = 240,
                Quantity = 24,
                PricebookEntryId=pricebookEntries[0].id,
                SBQQ__Activated__c = true,
                blng__InvoiceRunProcessingStatus__c = 'Pending Billing',
                SBQQ__ChargeType__c = 'One-Time'
        );

        insert orderItem;

        orderNew.Status = 'Activated';
        update orderNew;

    }


    @IsTest
    static void testBehavior() {

        Test.startTest();

        SBQQ.TriggerControl.disable();
        CV_OrderForceTaxRecalc batch = new CV_OrderForceTaxRecalc();
        Database.executeBatch(batch);

        Test.stopTest();

        List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, blng__TaxStatus__c FROM OrderItem]);

        System.assertEquals(1, orderItems.size());

    }

    @IsTest
    static void testSchedule() {

        String sch2 = '0 5 * * * ?';
        String jobId = CV_OrderForceTaxRecalc.scheduleThis(sch2);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);


    }

}