/**
 * Created by Michael on 10-07-22.
 */

@IsTest
private class CV_PDFManagementServiceTest {

    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{normalProduct}, pricebook2);

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
                PricebookEntryId=pricebookEntries[0].id
        );
        insert orderItem;

        SBQQ.TriggerControl.disable();

        orderNew.Status = 'Activated';
        update orderNew;

        SBQQ.TriggerControl.enable();

    }


    @IsTest
    static void testGeneratePDF() {

//        SBQQ.TriggerControl.disable();
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

        List<blng__Invoice__c> invoices = CV_PDFManagementService.generatePDFDocuments(new List<blng__Invoice__c>{testInvoice});

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>([
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :testInvoice.Id
        ]);
        System.assertEquals(1, contentDocumentLinks.size());

    }

    @IsTest
    static void testGetPDF() {

        SBQQ.TriggerControl.disable();
        Account account = [SELECT id FROM Account];

        OrderItem orderItem = [SELECT id,Product2Id FROM OrderItem LIMIT 1];

        blng__Invoice__c testInvoice = new blng__Invoice__c();
        testInvoice.blng__Account__c = account.Id;
        testInvoice.blng__InvoiceStatus__c = 'Posted';
        testInvoice.Statut_Integration_ECV__c = 'A Envoyer';
        insert testInvoice;

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c();
        testInvoiceLine.blng__Invoice__c = testInvoice.Id;
        testInvoiceLine.blng__OrderProduct__c = orderItem.Id;
        testInvoiceLine.blng__Product__c = orderItem.Product2Id;
        testInvoiceLine.blng__Subtotal__c = 100;
        insert testInvoiceLine;

        ContentVersion objVersion = new ContentVersion();
        objVersion.ContentLocation = 'S';
        objVersion.PathOnClient = testInvoice.Name +'.pdf';
        objVersion.Title = testInvoice.Name;
        objVersion.VersionData = blob.valueOf('Unit.Test');
        insert objVersion;
        System.debug('========================== TEST TEST contentVersion UNPAID Id  : ' + objVersion);

        Id objDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objVersion.Id].ContentDocumentId;
        ContentDocumentLink objDocumentLink = New ContentDocumentLink();
        objDocumentLink.LinkedEntityId = testInvoice.Id;
        objDocumentLink.ContentDocumentId = objDocId;
        objDocumentLink.shareType = 'V';
        insert objDocumentLink;

        ContentVersion objVersion2 = new ContentVersion();
        objVersion2.ContentLocation = 'S';
        objVersion2.PathOnClient = testInvoice.Name + '_PAYE' + '.pdf';
        objVersion2.Title = testInvoice.Name + '_PAYE';
        objVersion2.VersionData = blob.valueOf('Unit.Test');
        insert objVersion2;
        System.debug('========================== TEST TEST contentVersion PAID Id  : ' + objVersion2);

        Id objDocId2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objVersion2.Id].ContentDocumentId;
        ContentDocumentLink objDocumentLink2 = New ContentDocumentLink();
        objDocumentLink2.LinkedEntityId = testInvoice.Id;
        objDocumentLink2.ContentDocumentId = objDocId2;
        objDocumentLink2.shareType = 'V';
        insert objDocumentLink2;

        Test.startTest();
        testInvoice.Document_genere__c = true;

        Map<Id, ContentVersion> pdfsByInvoiceIds = CV_PDFManagementService.getPDFsByInvoiceIds(
                new Set<Id>{testInvoice.Id},
                new Map<Id, blng__Invoice__c>{testInvoice.Id => testInvoice},
                false);
        System.assertEquals('null', pdfsByInvoiceIds.get(testInvoice.Id).title);
        System.assertEquals(objVersion.Id, pdfsByInvoiceIds.get(testInvoice.Id).Id);

        blng__Payment__c payment = new blng__Payment__c(
                blng__Amount__c = 100,
                blng__Account__c = account.Id,
                blng__Invoice__c = testInvoice.Id,
                blng__Status__c = 'Posted'
        );
        insert payment;

        blng__PaymentAllocationInvoiceLine__c paymentAllocationInvoiceLine = new blng__PaymentAllocationInvoiceLine__c(
                blng__Payment__c = payment.Id,
                blng__InvoiceLine__c = testInvoiceLine.Id,
                blng__Amount__c = 100,
                blng__Type__c = 'Allocation'
        );
        insert paymentAllocationInvoiceLine;

        blng__Invoice__c invoice = [SELECT Id, Document_Facture_Acquittee_Envoye__c, blng__Balance__c, blng__TotalAmount__c, blng__Payments__c, blng__PaymentStatus__c, Allocation_lignes_de_factures__c FROM blng__Invoice__c];

        invoice.Document_Facture_Acquittee__c = true;

        pdfsByInvoiceIds = CV_PDFManagementService.getPDFsByInvoiceIds(
                new Set<Id>{invoice.Id},
                new Map<Id, blng__Invoice__c>{invoice.Id => invoice},
                false);
        System.debug('========================== TEST TEST contentVersion PAID : ' + pdfsByInvoiceIds.get(invoice.Id).title);
        System.assertEquals('null_PAYE', pdfsByInvoiceIds.get(invoice.Id).title);
        System.assertEquals(objVersion2.Id, pdfsByInvoiceIds.get(invoice.Id).Id);

        Test.stopTest();

    }
}