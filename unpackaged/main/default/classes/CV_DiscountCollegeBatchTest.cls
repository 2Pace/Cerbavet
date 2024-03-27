/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_DiscountCollegeBatchTest {

    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        account.Remise_REPLAY__c = 10;
        account.Remise_REPLAY_Cerbavet_College__c = true;
        update account;

        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 replayProduct = CV_DataFactory.createProduct('REPLAYS', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{replayProduct}, pricebook2);

        Order orderNew = new Order();
        orderNew.AccountId = account.Id;
        orderNew.Account = account;
        orderNew.EffectiveDate = system.today();
        orderNew.Pricebook2Id = pricebook2.Id;
        orderNew.Status = 'Draft';
        orderNew.blng__BillingDayOfMonth__c = '1';
        orderNew.SBQQ__PaymentTerm__c = 'Net 30';
        insert orderNew;

        OrderItem item = new OrderItem();
        item.OrderId = orderNew.Id;
        item.Product2Id = replayProduct.Id;
        item.Product2 = replayProduct;
        item.UnitPrice = 1;
        item.Quantity = 1;
        item.PricebookEntryId=pricebookEntries[0].id;
        item.SBQQ__Activated__c = true;
        item.SBQQ__QuotedListPrice__c = 1;
        item.Order = orderNew;

        insert item;

        SBQQ.TriggerControl.disable();

        orderNew.Status = 'Activated';
        update orderNew;

        SBQQ.TriggerControl.enable();

        OrderItem orderItem = [SELECT id,Product2Id FROM OrderItem LIMIT 1];

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet Proprio',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;

        blng__Invoice__c testInvoice = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id,
                blng__InvoiceDate__c = Date.today().addMonths(-1)
        );
        insert testInvoice;

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 5
        );
        insert testInvoiceLine;

    }

    @IsTest
    static void testBatchBehavior() {

        System.debug('==================== TEST TEST Order: ' + [SELECT id, AccountId, blng__BillingAccount__c FROM Order]);
        System.debug('==================== TEST TEST Order Item: ' + [SELECT id, OrderId, Order.AccountId FROM OrderItem]);
        System.debug('==================== TEST TEST Invoice: ' + [SELECT id, blng__Account__c, blng__TotalAmount__c FROM blng__Invoice__c]);


        Test.startTest();

        CV_DiscountCollegeBatch batch = new CV_DiscountCollegeBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        OrderItem orderItem = [SELECT Id, UnitPrice, blng__OverrideBillableUnitPrice__c, Product2.ProductCode, SBQQ__Activated__c, Order.Account.Remise_REPLAY_Cerbavet_College__c FROM OrderItem];
        System.debug('==================== TEST TEST orderItem: ' + orderItem);
        System.assertEquals(0.50, orderItem.blng__OverrideBillableUnitPrice__c);

    }


    @IsTest
    static void testSchedule() {

        System.Test.startTest();

        String sch2 = '0 5 * * * ?';
        String jobId = CV_DiscountCollegeBatch.scheduleThis(sch2);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        System.Test.stopTest();

    }
}