/**
 * Created by Michael on 08-07-22.
 */

public with sharing class CV_DataFactory {

    // Static variables to store inserted objects
    public static blng__LegalEntity__c legalEntityStatic;
    public static blng__BillingRule__c billRuleStatic;
    public static blng__FinanceBook__c financeBookStatic;
    public static blng__BillingTreatment__c billTrtStatic;
    public static blng__TaxRule__c taxRuleStatic;
    public static blng__TaxIntegration__c taxIngrtStatic;
    public static blng__TaxTreatment__c taxTrtStatic;
    public static blng__RevenueRecognitionRule__c revRecRuleStatic;
    public static BillingIDs__c billingIdsStatic;
    public static Account biSpeStatic;
    public static Pricebook2 pricebook2Static;
    public static List<PricebookEntry> pricebookEntriesStatic;
    public static Product2 productStatic;
    public static Tech_Hexalis_Dossier_Import__c dossierStatic;
    public static List<Tech_Hexalis_Order_Import__c> orderImportsStatic;
    
    public static blng__LegalEntity__c createLegalEntity() {

        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c(
            Name = 'TestLegal',
            blng__Active__c = true
        );
        insert legalEntity;
        legalEntityStatic = legalEntity;
        return legalEntity;
    }

    public static void configureBilling(blng__LegalEntity__c legalEntity) {

        blng__BillingRule__c billRule = new blng__BillingRule__c(
                Name = 'Cerba Vet College PRESTATIONS FORMATION 20%',
                blng__InitialBillingTrigger__c = 'Order Product Activation Date',
                blng__PartialPeriodTreatment__c = 'Separate',
                blng__PeriodTreatmentForBTDO__c = 'Exclude Billing Day Of Month',
                blng__Active__c = True,
                blng__GenerateInvoices__c = 'Yes'
        );
        insert billRule;
        billRuleStatic = billRule;

        blng__FinanceBook__c financeBook = new blng__FinanceBook__c(
                Name = 'Cerbavet College Accounting Book',
                blng__Active__c = True,
                blng__FinancePeriodDuration__c = 'Monthly',
                blng__PeriodType__c = 'Accounting'
        );
        insert financeBook;
        financeBookStatic = financeBook;

        blng__BillingTreatment__c billTrt = new blng__BillingTreatment__c(
                Name = 'Cerba Vet College PRESTATIONS FORMATION 20%',
                blng__BillingRule__c = billRule.Id,
                blng__BillingLegalEntity__c = legalEntity.Id,
                blng__BillingFinanceBook__c = financeBook.Id,
                blng__CancellationRule__c = 'LIFO by Order Product Creation Date'
        );
        insert billTrt;
        billTrtStatic = billTrt;

        blng__TaxRule__c taxRule = new blng__TaxRule__c(
                Name = 'Taxe France métropolitaine Cerbavet College',
                blng__Active__c = True,
                blng__TaxableYesNo__c = 'Yes'
        );
        insert taxRule;
        taxRuleStatic = taxRule;

        blng__TaxIntegration__c taxIngrt = new blng__TaxIntegration__c(
                Name = 'Taxe Intégration France Métropolitaine Cerbavet College',
                blng__TaxEngine__c = 'Standard',
                blng__Active__c = True
        );
        insert taxIngrt;
        taxIngrtStatic = taxIngrt;

        blng__TaxTreatment__c taxTrt = new blng__TaxTreatment__c(
                Name = 'Treatment France Métropolitaine Cerbavet College',
                blng__TaxLegalEntity__c = legalEntity.Id,
                blng__TaxRule__c = taxRule.Id,
                blng__TaxIntegration__c = taxIngrt.Id
        );
        insert taxTrt;
        taxTrtStatic = taxTrt;

        blng__RevenueRecognitionRule__c revRecRule = new blng__RevenueRecognitionRule__c(
                Name = 'Invoice Based.Full Recognition Cerbavet College',
                blng__CreateRevenueSchedule__c = 'Yes',
                blng__Active__c = True
        );
        insert revRecRule;
        revRecRuleStatic = revRecRule;

        BillingIDs__c billing = new BillingIDs__c(
                Legal_Entity_Cerbavet_College__c=legalEntity.Id,
                BillingRule_CVC_FRANCE__c = billRule.Id,
                BillingTreatment_CVC_FRANCE__c = billTrt.Id,
                TR_France_Metropolitaine_CVC__c = taxRule.Id,
                TT_France_metropolitaine_CVC__c = taxTrt.Id,
                RevenueRecognitionRule_Invoice_Full_CVC__c = revRecRule.Id
        );
        Insert billing;
        billingIdsStatic = billing;
    }

    public static Account createCompteSGL(Boolean isDefault) {

        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        Account biSpe = new Account(
                Raison_sociale__c = isDefault? 'DefaultAccount' : 'BiSpeR1',
                Name = isDefault? 'DefaultAccount' : 'BiSpeR1',
                RecordTypeId = recTypeBiSpe,
                CurrencyIsoCode = 'EUR',
                AccountNumber = isDefault ? 'HEX-119-A200' : 'HEX-119-12345',
                Code_compte_metier__c = isDefault ? 'A200' : '12345',
                Numero_instance_source__c = 119,
                BillingCountry = 'France'

        );
        insert biSpe;
        biSpeStatic = biSpe;

        return biSpe;
    }

    public static Pricebook2 createPriceBook() {

        Pricebook2 pricebook2 = new Pricebook2(
                Name = 'CerbaVet',
                CurrencyIsoCode = 'EUR'
        );

        insert pricebook2;
        pricebook2Static = pricebook2;

        return pricebook2;
    }

    public static List<PricebookEntry> createPriceBookEntries(List<Product2> products, Pricebook2 priceBook) {

        Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
        );
        // Run an update DML on the Pricebook2 record
        // This is the weird workaround that enables IsStandard to become true
        // on the PricebookEntry record
        update standardPricebook;
        

        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>();

        for (Product2 product : products) {
            PricebookEntry pbe = new PricebookEntry(
                    Pricebook2Id = priceBook.Id,
                    Product2Id = product.Id,
                    UnitPrice = product.ProductCode == 'ATEL' ? 0 : 1
            );
            pricebookEntries.add(pbe);

            PricebookEntry spbe = new PricebookEntry(
                    Pricebook2Id = standardPricebook.Id,
                    Product2Id = product.Id,
                    UnitPrice = product.ProductCode == 'ATEL' ? 0 : 1
            );
            standardPricebookEntries.add(spbe);
        }
        insert standardPricebookEntries;
        insert pricebookEntries;
        pricebookEntriesStatic = pricebookEntries;

        return pricebookEntries;

    }

    public static Product2 createProduct(String productCode, Boolean isDefault, Boolean nonDiscountable, Boolean degressif) {

        Product2 product = new Product2(
                Name = isDefault ? 'ATEL' : productCode,
                ProductCode = isDefault ? 'ATEL' : productCode,
                SBQQ__Taxable__c = true,
                SBQQ__ChargeType__c = 'One-Time',
                IsActive = true,
                SBQQ__NonDiscountable__c = nonDiscountable,
                Prix_Degressif__c = degressif
        );

        insert product;
        productStatic = product;

        return product;

    }

    public static void createBundle(Product2 bundle, Product2 product1, Product2 product2) {


        List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c option1 = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = bundle.Id,
                SBQQ__OptionalSKU__c = product1.Id,
                SBQQ__Number__c = 1
        );
        options.add(option1);

        SBQQ__ProductOption__c option2 = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = bundle.Id,
                SBQQ__OptionalSKU__c = product2.Id,
                SBQQ__Number__c = 2

        );
        options.add(option2);
        insert options;

    }

    public static Tech_Hexalis_Dossier_Import__c createDossier(Account account) {

        Tech_Hexalis_Dossier_Import__c dossier = new Tech_Hexalis_Dossier_Import__c(
                Code_Patient__c = '1235',
                Date_Creation_Dossier__c = '2022-01-01',
                Email_Patient__c = 'test@test.com',
                Prenom_Patient__c = 'TestAnimal',
                Nom_Patient__c = 'TestNom',
                Code_Dossier__c = 'C44353535',
                Code_Correspondant__c = account.Code_compte_metier__c
        );

        insert dossier;
        dossierStatic = dossier;

        return dossier;

    }

    public static List<Tech_Hexalis_Order_Import__c> createCodesExamen(List<Product2> products, Tech_Hexalis_Dossier_Import__c dossier, Boolean addUnkown) {

        List<Tech_Hexalis_Order_Import__c> orderImports = new List<Tech_Hexalis_Order_Import__c>();

        for (Product2 product : products) {
            Tech_Hexalis_Order_Import__c techHexalisOrderImport = new Tech_Hexalis_Order_Import__c(
                    Code_Dossier__c = dossier.Code_Dossier__c,
                    Code_Examen__c = product.ProductCode
            );

            orderImports.add(techHexalisOrderImport);
        }

        if (addUnkown) {
            Tech_Hexalis_Order_Import__c techHexalisOrderImport = new Tech_Hexalis_Order_Import__c(
                    Code_Dossier__c = dossier.Code_Dossier__c,
                    Code_Examen__c = 'UNKOW'
            );

            orderImports.add(techHexalisOrderImport);
        }

        insert orderImports;
        orderImportsStatic = orderImports;
        return orderImports;
    }
}