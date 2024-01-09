/**
 * Created by Michael on 20-07-22.
 */

@IsTest
private class InvoiceTriggerHandlerTest {

    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{
                normalProduct
        }, pricebook2);

        SBQQ.TriggerControl.disable();

        Order orderNew = new Order(
                AccountId = account.Id,
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebook2.Id,
                Status = 'Draft',
                blng__BillingDayOfMonth__c = '1',
                SBQQ__PaymentTerm__c = 'Net 30',
                blng__InvoiceBatch__c = 'Cerbavet Analysis',
                IDDossier__c = 'Dossier123456'
        );
        insert orderNew;

        OrderItem orderItem = new OrderItem(
                OrderId = orderNew.Id,
                Product2Id = normalProduct.Id,
                UnitPrice = 240,
                Quantity = 24,
                PricebookEntryId = pricebookEntries[0].id
        );

        insert orderItem;

        orderNew.Status = 'Activated';
        update orderNew;

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet Proprio',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;

        blng__Invoice__c testInvoice = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id,
                Statut_Integration_ECV__c = 'A Envoyer'
        );
        insert testInvoice;

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine;

        blng__InvoiceRun__c invoiceRun2 = new blng__InvoiceRun__c(
                Name = 'Cerbavet Proprio Suisse',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun2;

        blng__Invoice__c testInvoice2 = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun2.Id,
                Statut_Integration_ECV__c = 'A Envoyer'
        );
        insert testInvoice2;

        blng__InvoiceLine__c testInvoiceLine2 = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice2.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine2;

        blng__InvoiceRun__c invoiceRun3 = new blng__InvoiceRun__c(
                Name = 'Cerbavet College',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun3;

        blng__Invoice__c testInvoice3 = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun3.Id,
                Statut_Integration_ECV__c = 'A Envoyer'
        );
        insert testInvoice3;

        blng__InvoiceLine__c testInvoiceLine3 = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice3.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine3;

    }


    @IsTest
    static void testBehavior() {

        Account account = [SELECT Id FROM Account];
        blng__InvoiceRun__c invoiceRun = [SELECT Id FROM blng__InvoiceRun__c WHERE Name = 'Cerbavet Proprio'];
        OrderItem orderItem = [SELECT Id, Product2Id FROM OrderItem];

        blng__Invoice__c testInvoice = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id,
                Statut_Integration_ECV__c = 'A Envoyer'
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

        List<blng__Invoice__c> invoices = new List<blng__Invoice__c>([
                SELECT Id, Numero_Facturation_Cerbavet__c, blng__Order__c, IDDossier__c
                FROM blng__Invoice__c
                WHERE blng__InvoiceRunCreatedBy__r.Name = 'Cerbavet Proprio'
                ORDER BY Numero_Facturation_Cerbavet__c]);

        System.assertEquals(2, invoices.size());
        System.assert(invoices[0].Numero_Facturation_Cerbavet__c.contains('0001'));
        System.assert(invoices[0].Numero_Facturation_Cerbavet__c.contains('FACCV'));
        System.assert(invoices[1].Numero_Facturation_Cerbavet__c.contains('0002'));


        List<blng__Invoice__c> invoicesSuisse = new List<blng__Invoice__c>([
                SELECT Id, Numero_Facturation_Cerbavet__c
                FROM blng__Invoice__c
                WHERE blng__InvoiceRunCreatedBy__r.Name = 'Cerbavet Proprio Suisse'
                ORDER BY Numero_Facturation_Cerbavet__c]);

        System.assert(invoicesSuisse[0].Numero_Facturation_Cerbavet__c.contains('0001'));
        System.assert(invoicesSuisse[0].Numero_Facturation_Cerbavet__c.contains('FACCH'));

        List<blng__Invoice__c> invoicesCollege = new List<blng__Invoice__c>([
                SELECT Id, Numero_Facturation_Cerbavet__c
                FROM blng__Invoice__c
                WHERE blng__InvoiceRunCreatedBy__r.Name = 'Cerbavet College'
                ORDER BY Numero_Facturation_Cerbavet__c]);

        System.assert(invoicesCollege[0].Numero_Facturation_Cerbavet__c.contains('0001'));
        System.assert(invoicesCollege[0].Numero_Facturation_Cerbavet__c.contains('FACCC'));

        Test.stopTest();

    }
}