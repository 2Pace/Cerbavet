/**
 * Created by Michael on 10-07-22.
 */

@IsTest
private class CV_InvoicePDFCreatorBatchTest {

    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{normalProduct}, pricebook2);

        Order orderNew = new Order();
        orderNew.AccountId = account.Id;
        orderNew.EffectiveDate = system.today();
        orderNew.Pricebook2Id = pricebook2.Id;
        orderNew.Status = 'Draft';
        orderNew.blng__BillingDayOfMonth__c = '1';
        orderNew.SBQQ__PaymentTerm__c = 'Net 30';
        insert orderNew;

        OrderItem item = new OrderItem();
        item.OrderId = orderNew.Id;
        item.Product2Id = normalProduct.Id;
        item.UnitPrice = 240;
        item.Quantity = 24;
        item.PricebookEntryId=pricebookEntries[0].id;

        insert item;

        SBQQ.TriggerControl.disable();

        orderNew.Status = 'Activated';
        update orderNew;

        SBQQ.TriggerControl.enable();

    }

    @IsTest
    static void testBatchBehavior() {

        SBQQ.TriggerControl.disable();
        Account account = [SELECT id FROM Account];
        Order order = [SELECT Id FROM Order];
        order.blng__InvoiceBatch__c = 'Cerbavet Analysis';
        Update order;

        OrderItem orderItem = [SELECT id,Product2Id FROM OrderItem LIMIT 1];

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet Proprio',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;

        blng__Invoice__c testInvoice = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id
        );
        insert testInvoice;

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine;

        Test.startTest();

        CV_InvoicePDFCreatorBatch batch = new CV_InvoicePDFCreatorBatch(false);
        Database.executeBatch(batch);

        Test.stopTest();

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>([
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :testInvoice.Id
        ]);
        System.assertEquals(1, contentDocumentLinks.size());

    }

    @IsTest
    static void testSchedule() {

        System.Test.startTest();

        String sch2 = '0 5 * * * ?';

        String jobId = CV_InvoicePDFCreatorBatch.scheduleThis(sch2, true);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);
        System.Test.stopTest();

    }
}