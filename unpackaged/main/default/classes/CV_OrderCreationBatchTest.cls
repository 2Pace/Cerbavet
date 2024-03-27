/**
 * Created by Michael on 08-07-22.
 */

@IsTest
private class CV_OrderCreationBatchTest {

    @TestSetup
    static void setupData() {
        
        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account defaultAccount = CV_DataFactory.createCompteSGL(true);
        defaultAccount.BillingCountry = 'France';
        defaultAccount.Facturation_coursier__c = 2;
        defaultAccount.Facturation_coursier_reduit__c = 1;
        update defaultAccount;
        Account account = CV_DataFactory.createCompteSGL(false);
        account.Facturation_coursier__c = 2;
        account.Facturation_coursier_reduit__c = 1;
        account.BillingCountry = 'France';
        update account;
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 atelProduct = CV_DataFactory.createProduct('ATEL', true, true, false);
        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);
        Product2 degressifProduct = CV_DataFactory.createProduct('DEGRES', false, false, true);
        Product2 transProduct = CV_DataFactory.createProduct('TRAN', false, true, false);
        Product2 fdd8 = CV_DataFactory.createProduct('FDD8', false, true, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{atelProduct,normalProduct,degressifProduct,fdd8}, pricebook2);

        Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
        );

        PricebookEntry spbe = new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = transProduct.Id,
                UnitPrice = 0
        );
        insert spbe;

        PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pricebook2.Id,
                Product2Id = transProduct.Id,
                UnitPrice = 0
        );
        insert pbe;

        Tech_Hexalis_Dossier_Import__c dossier = CV_DataFactory.createDossier(account);
        List<Tech_Hexalis_Order_Import__c> codesExamen = CV_DataFactory.createCodesExamen(new List<Product2>{normalProduct, degressifProduct}, dossier, true);

    }

    @IsTest
    static void testBatchBehaviourNoBundles() {

        System.debug('================ TEST TEST Account: ' + [SELECT Id, AccountNumber, Name FROM Account]);

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, Product2.ProductCode, Code_produit_Hexalis__c, UnitPrice, ListPrice FROM OrderItem]);
        System.debug('================================== TEST TEST orderItems: ' + orderItems);

    }

    @IsTest
    static void testBatchBehaviourWithBundlesInExam() {

        Pricebook2 pricebook2 = [SELECT Id FROM Pricebook2 WHERE Name = 'Cerbavet'];
        Product2 normalProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'PARSG'];
        Product2 dregesProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'DEGRES'];
        Product2 bundle = CV_DataFactory.createProduct('BUNDLE', false, false, false);
        Tech_Hexalis_Dossier_Import__c dossier = [SELECT Id, Code_Dossier__c FROM Tech_Hexalis_Dossier_Import__c];

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{bundle}, pricebook2);

        CV_DataFactory.createBundle(bundle, normalProduct, dregesProduct);

        List<Tech_Hexalis_Order_Import__c> codesExamen = CV_DataFactory.createCodesExamen(new List<Product2>{bundle}, dossier, true);

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, Product2.ProductCode, Code_produit_Hexalis__c, UnitPrice, ListPrice FROM OrderItem]);
        System.assertEquals(3, orderItems.size());

        Boolean foundBundle = false;
        for (OrderItem orderItem : orderItems) {
            if (orderItem.Product2.ProductCode == 'BUNDLE') {
                foundBundle = true;
            }
        }
        System.assertEquals(true, foundBundle);

    }

    @IsTest
    static void testBatchBehaviourWithoutBundlesInExam() {

        Pricebook2 pricebook2 = [SELECT Id FROM Pricebook2 WHERE Name = 'Cerbavet'];
        Product2 normalProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'PARSG'];
        Product2 dregesProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'DEGRES'];
        Product2 bundle = CV_DataFactory.createProduct('BUNDLE', false, false, false);
        Tech_Hexalis_Dossier_Import__c dossier = [SELECT Id, Code_Dossier__c FROM Tech_Hexalis_Dossier_Import__c];

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{bundle}, pricebook2);

        CV_DataFactory.createBundle(bundle, normalProduct, dregesProduct);

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, Product2.ProductCode, Code_produit_Hexalis__c, UnitPrice, ListPrice FROM OrderItem]);

        System.assertEquals(3, orderItems.size());

        Boolean foundBundle = false;
        for (OrderItem orderItem : orderItems) {
            if (orderItem.Product2.ProductCode == 'BUNDLE') {
                foundBundle = true;
            }
        }
        System.assertEquals(true, foundBundle);

    }

    @IsTest
    static void testBatchNoCodeExams() {

        List<Tech_Hexalis_Order_Import__c> orderImports = new List<Tech_Hexalis_Order_Import__c>([SELECT Id FROM Tech_Hexalis_Order_Import__c]);
        delete orderImports;

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        List<Order> orders = new List<Order>([SELECT Id FROM Order]);
        System.assertEquals(true, orders.isEmpty());

    }

    @IsTest
    static void testBatchDiscountGlobal() {

        Account account = [SELECT Id, Conditions_de_Reglement_Cerbavet__c, Remise_sur_facture_Cerba_Vet__c FROM Account WHERE Raison_sociale__c = 'BiSpeR1'];
        account.Remise_sur_facture_Cerba_Vet__c = 10;
        update account;

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, Product2.ProductCode, Code_produit_Hexalis__c, UnitPrice, ListPrice FROM OrderItem]);

        System.debug('=============== TEST TEST orderItems: ' + orderItems);

        System.assertEquals(4, orderItems.size());

        Boolean priceOK = false;
        for (OrderItem orderItem : orderItems) {
            if (orderItem.UnitPrice == 0.9) {
                priceOK = true;
            }
        }
        System.assertEquals(true, priceOK);

    }

    @IsTest
    static void testIrrelevantCode() {

        Tech_Hexalis_Dossier_Import__c dossier = [SELECT Id, Code_Dossier__c, Code_Correspondant__c FROM Tech_Hexalis_Dossier_Import__c];

        Tech_Hexalis_Order_Import__c techHexalisOrderImport = new Tech_Hexalis_Order_Import__c(
                Code_Examen__c = 'CBO',
                Code_Dossier__c = dossier.Code_Dossier__c
        );
        insert techHexalisOrderImport;

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, Product2.ProductCode, Code_produit_Hexalis__c, UnitPrice, ListPrice FROM OrderItem]);

        System.assertEquals(4, orderItems.size());

    }

    @IsTest
    static void testMandatoryCode() {

        Pricebook2 pricebook2 = [SELECT Id FROM Pricebook2 WHERE Name = 'Cerbavet'];
        Product2 cybac = CV_DataFactory.createProduct('CYBAC', false, false, false);
        Product2 acyli = CV_DataFactory.createProduct('ACYLI', false, false, false);
        Product2 dregesProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'DEGRES'];

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{cybac, acyli}, pricebook2);

        CV_DataFactory.createBundle(cybac, acyli, dregesProduct);

        Tech_Hexalis_Dossier_Import__c dossier = [SELECT Id, Code_Dossier__c, Code_Correspondant__c FROM Tech_Hexalis_Dossier_Import__c];

        List<Tech_Hexalis_Order_Import__c> codeExams = new List<Tech_Hexalis_Order_Import__c>();
        Tech_Hexalis_Order_Import__c techHexalisOrderImport = new Tech_Hexalis_Order_Import__c(
                Code_Examen__c = 'ACYLI',
                Code_Dossier__c = dossier.Code_Dossier__c
        );
        codeExams.add(techHexalisOrderImport);

        techHexalisOrderImport = new Tech_Hexalis_Order_Import__c(
                Code_Examen__c = 'CYBAC',
                Code_Dossier__c = dossier.Code_Dossier__c
        );
        codeExams.add(techHexalisOrderImport);

        insert codeExams;

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, Product2.ProductCode, Code_produit_Hexalis__c, UnitPrice, ListPrice FROM OrderItem]);
        System.assertEquals(4, orderItems.size());

    }

    @IsTest
    static void testInvalidAccount() {

        Tech_Hexalis_Dossier_Import__c dossier = [SELECT Id, Code_Dossier__c, Code_Correspondant__c FROM Tech_Hexalis_Dossier_Import__c];
        dossier.Code_Correspondant__c = 'AZAERZR';
        update dossier;

        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        Order order = [SELECT Id, Status, Statut__c, Message_Integration_Hexalis__c FROM Order];
        //System.assertEquals('Code correspondant inconnu: HEX-119-AZAERZR', order.Message_Integration_Hexalis__c);

    }

    @IsTest
    static void testBatchActivationOrder() {

        Account account = [SELECT Id, Conditions_de_Reglement_Cerbavet__c FROM Account WHERE Raison_sociale__c = 'BiSpeR1'];
        account.Conditions_de_Reglement_Cerbavet__c = 'Non Régleur';
        update account;

        Tech_Hexalis_Order_Import__c techHexalisOrderImport = [SELECT Id FROM Tech_Hexalis_Order_Import__c WHERE Code_Examen__c = 'UNKOW'];
        delete techHexalisOrderImport;

        Test.startTest();

//        SBQQ.TriggerControl.disable();
        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        Order order = [SELECT Id, Status, Statut__c FROM Order];
        System.assertEquals('Activated', order.Status);

    }

    @IsTest
    static void testBatchAtelCode() {

        Tech_Hexalis_Order_Import__c techHexalisOrderImport = [SELECT Id FROM Tech_Hexalis_Order_Import__c WHERE Code_Examen__c = 'UNKOW'];
        delete techHexalisOrderImport;


        Tech_Hexalis_Dossier_Import__c dossier = [SELECT Id, Code_Dossier__c FROM Tech_Hexalis_Dossier_Import__c];

        techHexalisOrderImport = new Tech_Hexalis_Order_Import__c(
                Code_Examen__c = 'ATEL',
                Code_Dossier__c = dossier.Code_Dossier__c
        );
        insert techHexalisOrderImport;


        Test.startTest();

        CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        Order order = [SELECT Id, Status, Statut__c, Message_Integration_Hexalis__c FROM Order];
        System.assertEquals('Code ATEL Présent', order.Message_Integration_Hexalis__c);

    }


    @IsTest
    static void testSchedule() {

        System.Test.startTest();

        String sch2 = '0 5 * * * ?';
        CV_OrderCreationBatch sqrb2 = new CV_OrderCreationBatch();
        String jodId = System.schedule('testJob', sch2, sqrb2);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jodId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);
        System.Test.stopTest();

    }

}