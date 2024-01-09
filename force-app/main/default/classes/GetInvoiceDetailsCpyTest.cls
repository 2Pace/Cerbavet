@isTest
public class GetInvoiceDetailsCpyTest
{
    @testSetup static void setupData()
    {
        sbqq.triggercontrol.disable();
        String fieldValue = 'TestValue';
        String fieldValue2 = 'TestValue2';
        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
        legalEntity.Name = 'Cerbavet College';
        legalEntity.blng__Active__c = True;
        legalEntity.blng__Country__c = 'France';
        insert legalEntity;
        
        blng__BillingRule__c billRule = new blng__BillingRule__c();
        billRule.Name = 'Cerba Vet College PRESTATIONS FORMATION 20%';
        billRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        billRule.blng__PartialPeriodTreatment__c = 'Separate';
        billRule.blng__PeriodTreatmentForBTDO__c = 'Exclude Billing Day Of Month';
        billRule.blng__Active__c = True;
        billRule.blng__GenerateInvoices__c = 'Yes';
        insert billRule;
        
        blng__FinanceBook__c financeBook = new blng__FinanceBook__c();
        financeBook.Name = 'Cerbavet College Accounting Book';
        financeBook.blng__Active__c = True;
        financeBook.blng__FinancePeriodDuration__c = 'Monthly';
        financeBook.blng__PeriodType__c = 'Accounting';
        insert financeBook;
        
        blng__BillingTreatment__c billTrt = new blng__BillingTreatment__c();
        billTrt.Name = 'Cerba Vet College PRESTATIONS FORMATION 20%';
        billTrt.blng__BillingRule__c = billRule.Id;
        billTrt.blng__BillingLegalEntity__c = legalEntity.Id;
        billTrt.blng__BillingFinanceBook__c = financeBook.Id;
        billTrt.blng__CancellationRule__c = 'LIFO by Order Product Creation Date';
        insert billTrt;
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Taxe France métropolitaine Cerbavet College';
        taxRule.blng__Active__c = True;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        blng__TaxIntegration__c taxIngrt = new blng__TaxIntegration__c();
        taxIngrt.Name = 'Taxe Intégration France Métropolitaine Cerbavet College';
        taxIngrt.blng__TaxEngine__c = 'Standard';
        taxIngrt.blng__Active__c = True;
        insert taxIngrt;
            
        blng__TaxTreatment__c taxTrt = new blng__TaxTreatment__c();
        taxTrt.Name = 'Treatment France Métropolitaine Cerbavet College';
        taxTrt.blng__TaxLegalEntity__c = legalEntity.Id;
        taxTrt.blng__TaxRule__c = taxRule.Id;
        taxTrt.blng__TaxIntegration__c = taxIngrt.Id;
        insert taxTrt;
        
        blng__RevenueRecognitionRule__c revRecRule = new blng__RevenueRecognitionRule__c();
        revRecRule.Name = 'Invoice Based.Full Recognition Cerbavet College';
        revRecRule.blng__CreateRevenueSchedule__c = 'Yes';
        revRecRule.blng__Active__c = True;
        insert revRecRule;
        
        BillingIDs__c billing = new BillingIDs__c();
        billing.Legal_Entity_Cerbavet_College__c=legalEntity.Id ;
        billing.BillingRule_CVC_FRANCE__c = billRule.Id;
        billing.BillingTreatment_CVC_FRANCE__c = billTrt.Id;
        billing.TR_France_Metropolitaine_CVC__c = taxRule.Id;
        billing.TT_France_metropolitaine_CVC__c = taxTrt.Id;
        billing.RevenueRecognitionRule_Invoice_Full_CVC__c = revRecRule.Id;
        Insert billing;
        
        Account a1 = new Account();
        a1.Name = 'TestAccount';
        a1.billingcountry = 'france';
        insert a1;
        //Create Product
        Product2 pro = new Product2(Name = 'PARCOURS HEMATOLOGIE / CYTOLOGIE', Family = 'Cerbavet College',ProductCode='FORM',SBQQ__ChargeType__c='One-Time');
        Insert pro;
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        //Create the PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = pro.Id,
            UnitPrice = 1020,
            IsActive = true
        );
        Insert pbe;
        Order orderNew = new Order();
        orderNew.AccountId = a1.Id;
        orderNew.EffectiveDate = system.today();
        orderNew.Pricebook2Id = standardPricebook.Id;
        orderNew.Status = 'Draft';
        orderNew.blng__BillingDayOfMonth__c = '1';
        orderNew.SBQQ__PaymentTerm__c = 'Net 30';
        insert orderNew;
       System.debug('orderneew-------'+ orderNew);
        OrderItem item = new OrderItem();
        item.OrderId = orderNew.Id;
        item.Product2Id = pro.Id;
        item.UnitPrice = 240;
        item.Quantity = 24;
        item.PricebookEntryId=pbe.id;
        System.debug('item-------'+ item);
        insert item;
        
        orderNew.Status = 'Activated';
        update orderNew;
    }
    @isTest static void passValueToControllerTest()
    {
        sbqq.triggercontrol.disable();
        Account acc= [Select id from account where name=:'TestAccount'];
        order orders = [Select Id from order];
        OrderItem Oi = [Select id,Product2Id from OrderItem LIMIT 1];

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet Proprio',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;
        
        blng__Invoice__c testInvoice = new blng__Invoice__c();
        testInvoice.blng__Account__c = acc.Id;
        testInvoice.blng__InvoiceRunCreatedBy__c = invoiceRun.Id;
        insert testInvoice;
        
        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c();
        testInvoiceLine.blng__Invoice__c = testInvoice.Id;
        testInvoiceLine.blng__OrderProduct__c = Oi.Id;
        testInvoiceLine.blng__Product__c = Oi.Product2Id;
        testInvoiceLine.blng__Subtotal__c = 100;
        insert testInvoiceLine;
        test.starttest();
        PageReference pageRef = Page.InvoiceTemplateMain; // Add your VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', String.valueOf(testInvoice.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(testInvoice);
        GetInvoiceDetailsCpy testAccPlan = new GetInvoiceDetailsCpy(sc);
        //testAccPlan.passValueToController();
        Test.stopTest();
    }
    @isTest static void passValueToControllerTest2()
    {
        sbqq.triggercontrol.disable();
        Account acc= [Select id from account where name=:'TestAccount'];
        order orders = [Select Id from order];
        orders.blng__InvoiceBatch__c = 'Cerbavet Analysis';
        Update orders;
        
        OrderItem Oi = [Select id,Product2Id from OrderItem LIMIT 1];

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet Clinics Monthly',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;
        
        blng__Invoice__c testInvoice = new blng__Invoice__c();
        testInvoice.blng__Account__c = acc.Id;
        testInvoice.blng__InvoiceRunCreatedBy__c = invoiceRun.Id;
        insert testInvoice;
        
        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c();
        testInvoiceLine.blng__Invoice__c = testInvoice.Id;
        testInvoiceLine.blng__OrderProduct__c = Oi.Id;
        testInvoiceLine.blng__Product__c = Oi.Product2Id;
        testInvoiceLine.blng__Subtotal__c = 100;
        insert testInvoiceLine;
        test.starttest();
        PageReference pageRef = Page.InvoiceTemplateMain; // Add your VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', String.valueOf(testInvoice.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(testInvoice);
        GetInvoiceDetailsCpy testAccPlan = new GetInvoiceDetailsCpy(sc);
        //testAccPlan.passValueToController();
        Test.stopTest();
    }
    
    @isTest static void passValueToControllerTest3()
    {
        sbqq.triggercontrol.disable();
        Account acc= [Select id from account where name=:'TestAccount'];
        order orders = [Select Id from order];
        orders.blng__InvoiceBatch__c = 'Cerbavet Analysis Proprio';
        
        Update orders;
        
        OrderItem Oi = [Select id,Product2Id from OrderItem LIMIT 1];

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet College',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;

        blng__Invoice__c testInvoice = new blng__Invoice__c();
        testInvoice.blng__Account__c = acc.Id;
        testInvoice.blng__InvoiceRunCreatedBy__c = invoiceRun.Id;
        insert testInvoice;
        
        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c();
        testInvoiceLine.blng__Invoice__c = testInvoice.Id;
        testInvoiceLine.blng__OrderProduct__c = Oi.Id;
        testInvoiceLine.blng__Product__c = Oi.Product2Id;
        testInvoiceLine.blng__Subtotal__c = 100;
        insert testInvoiceLine;
        test.starttest();
        PageReference pageRef = Page.InvoiceTemplateMain; // Add your VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', String.valueOf(testInvoice.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(testInvoice);
        GetInvoiceDetailsCpy testAccPlan = new GetInvoiceDetailsCpy(sc);
        //testAccPlan.passValueToController();
        Test.stopTest();
    }
    @isTest static void passValueToControllerTest4()
    {
        sbqq.triggercontrol.disable();
        Account acc= [Select id from account where name=:'TestAccount'];
        order orders = [Select Id from order];
        orders.blng__InvoiceBatch__c = 'Cerbavet Analysis';
        orders.blng__BillingAccount__c = acc.id;
        Update orders;
        
        OrderItem Oi = [Select id,Product2Id from OrderItem LIMIT 1];
        
        blng__Invoice__c testInvoice = new blng__Invoice__c();
        testInvoice.blng__Account__c = acc.Id;
        insert testInvoice;
        
        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c();
        testInvoiceLine.blng__Invoice__c = testInvoice.Id;
        testInvoiceLine.blng__OrderProduct__c = Oi.Id;
        testInvoiceLine.blng__Product__c = Oi.Product2Id;
        testInvoiceLine.blng__Subtotal__c = 100;
        insert testInvoiceLine;
        test.starttest();
        PageReference pageRef = Page.InvoiceTemplateMain; // Add your VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', String.valueOf(testInvoice.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(testInvoice);
        GetInvoiceDetailsCpy testAccPlan = new GetInvoiceDetailsCpy(sc);
        testAccPlan.passValueToController();
        Test.stopTest();
    }
    @isTest static void getCurrencySymbolTest()
    {
        sbqq.triggercontrol.disable();
        String currencyIso = 'USD';
        Test.startTest();
        GetInvoiceDetailsCpy.getCurrencySymbol();
        Test.stopTest();
    }
}