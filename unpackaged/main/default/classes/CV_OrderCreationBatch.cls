/**
 * @description       : Batch permettant de créer les commandes depuis les codes examens importés depuis Hexalis
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 19-04-2022
 * @last modified by  : Michaël Cabaraux
**/

global class CV_OrderCreationBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Create_Order_Batch';
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_ACTIVATED = 'Activated';
    private static final String STATUS_TREATED = 'Traite';
    private static final String ATEL_CODE = 'ATEL';

    private CV_Batch_Settings__mdt batchSettings;
    private Id atelProductId;
    private Account defaultAccount;
//    private Set<String> dossiersToDelete;

    private Set<String> ordersToSendForActivation;
    private Map<String, Id> ordersToSendForTransport;

    private CV_OrderCreationService cvOrderCreationService;

    global Database.querylocator start(Database.BatchableContext bc) {

        cvOrderCreationService = new CV_OrderCreationService();

        ordersToSendForTransport = new Map<String, Id>();
        ordersToSendForActivation = new Set<String>();

        batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Account_Name__c, Keep_Records__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        defaultAccount = [SELECT Id, Conditions_de_Reglement_Cerbavet__c, CurrencyIsoCode, BillingCountry FROM Account WHERE (Id = :batchSettings.Default_Account_Id__c OR Raison_sociale__c = :batchSettings.Default_Account_Name__c) LIMIT 1];

        atelProductId = [SELECT Id FROM Product2 WHERE ProductCode = 'ATEL'].Id;

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Tech_Hexalis_Dossier_Import__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' FROM Tech_Hexalis_Dossier_Import__c';
        query += ' WHERE Statut_Traitement__c = \'New\'';
//        query += ' AND Code_Dossier__c in (\'09/03/22-1-0075\', \'07/02/23-1-0094\')';
        query += ' ORDER BY Code_Dossier__c';
//        query += ' LIMIT 100';

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }

    global void execute(Database.BatchableContext bc, List<Tech_Hexalis_Dossier_Import__c> hexalisDossiers) {

//        cvOrderCreationService.loadProductInformation();
//        cvOrderCreationService.loadPricingInformation();
//        cvOrderCreationService.loadCodeInformation();

        Set<String> dossiersToDelete = new Set<String>();
        Map<String, List<String>> examCodesByDossierIds = new Map<String, List<String>>();
        Map<String, String> codeCorrespodantsByDossierIds = new Map<String, String>();
        Map<String, Tech_Hexalis_Order_Import__c> mainTechInfosByDossiersIds = new Map<String, Tech_Hexalis_Order_Import__c>();

        Id rtId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Cerbavet_Analyses').getRecordTypeId();

        Map<String, List<Tech_Hexalis_Order_Import__c>> examenInfosByCodeDossiers =  cvOrderCreationService.getExamenInfosByCodeDossiers(hexalisDossiers);
        Map<String, Tech_Hexalis_Dossier_Import__c> dossierInfosByCodeDossiers = cvOrderCreationService.getDossierInfosByCodeDossiers(hexalisDossiers);

        for (String dossierId  : examenInfosByCodeDossiers.keyset()) {
            Tech_Hexalis_Dossier_Import__c techHexalisDossierImport = dossierInfosByCodeDossiers.get(dossierId);
            for (Tech_Hexalis_Order_Import__c techHexalisOrderImport : examenInfosByCodeDossiers.get(dossierId)) {

                if (!examCodesByDossierIds.containsKey(techHexalisOrderImport.Code_Dossier__c)) {
                    examCodesByDossierIds.put(techHexalisOrderImport.Code_Dossier__c, new List<String>());
                }

                List<String> examCodes = examCodesByDossierIds.get(techHexalisOrderImport.Code_Dossier__c);

                examCodes.add(techHexalisOrderImport.Code_Examen__c);

                String prefixedCodeCorrespondant = System.Label.CV_Hexalis_Prefix + techHexalisDossierImport.Code_Correspondant__c;
                codeCorrespodantsByDossierIds.put(techHexalisOrderImport.Code_Dossier__c, prefixedCodeCorrespondant);

                mainTechInfosByDossiersIds.put(techHexalisOrderImport.Code_Dossier__c, techHexalisOrderImport);

            }
        }


        System.debug('========================== CV_OrderCreationBatch examCodesByDossierIds: ' + examCodesByDossierIds);
        System.debug('========================== CV_OrderCreationBatch codeCorrespodantsByDossierIds: ' + codeCorrespodantsByDossierIds);

        Map<String, CV_OrderCreationService.InformationDossier> cleanedInformationDossiersByDossierIds = cvOrderCreationService.getCleanedInformationDossiers(codeCorrespodantsByDossierIds, examCodesByDossierIds, mainTechInfosByDossiersIds);

        System.debug('========================== CV_OrderCreationBatch cleanedExamLinesPerDossier: ' + cleanedInformationDossiersByDossierIds);

        Map<String, Map<String, CV_OrderCreationService.PricingInfo>> pricesByCodeExamsByDossiersIds = cvOrderCreationService.getPricesPerProductCodesPerDossierIds(cleanedInformationDossiersByDossierIds);
        System.debug('========================== CV_OrderCreationBatch returned pricesByCodeExamsByDossiersIds: ' + pricesByCodeExamsByDossiersIds);

        List<Order> ordersToCreate = new List<Order>();
        List<OrderItem> orderItemsToCreate = new List<OrderItem>();

//        Set<String> ordersToActivate = new Set<String>();

        for (String dossierId : cleanedInformationDossiersByDossierIds.keySet()) {

            System.debug('========================== CV_OrderCreationBatch dossierId: ' + dossierId);

            CV_OrderCreationService.InformationDossier informationDossier = cleanedInformationDossiersByDossierIds.get(dossierId);

            System.debug('========================== CV_OrderCreationBatch informationDossier: ' + informationDossier);

//            Tech_Hexalis_Order_Import__c techHexalisOrderImport = informationDossier.mainTechInfo;
            Tech_Hexalis_Dossier_Import__c techHexalisDossierImport = dossierInfosByCodeDossiers.get(dossierId);

            String techId =  techHexalisDossierImport.Id + '-' + dossierId + '-' +  + Integer.valueof((Math.random() * 1000));
            Account accountToConsider = informationDossier.accountInfo != null ? informationDossier.accountInfo : defaultAccount;

            String status = (informationDossier.isAtel || accountToConsider.Conditions_de_Reglement_Cerbavet__c != 'Non Régleur'
                    || informationDossier.accountInfo == null || (String.isBlank(techHexalisDossierImport.Email_Patient__c) && accountToConsider.Conditions_de_Reglement_Cerbavet__c == 'Non Régleur'))? STATUS_DRAFT : STATUS_ACTIVATED;

            String facturable = status == STATUS_ACTIVATED ? 'Oui' : 'Non';

            if (status.equalsIgnoreCase(STATUS_ACTIVATED)) {
//                ordersToActivate.add(techId);
                ordersToSendForActivation.add(techId);
            }

            String pricebookId = informationDossier.pricebookId != null ? informationDossier.pricebookId : cvOrderCreationService.getPricebookId(accountToConsider.BillingCountry);
            System.debug('========================== CV_OrderCreationBatch infosPricing pricebookId: ' + pricebookId);

            Order order = new Order(
                    AccountId = accountToConsider.Id,
                    Code_Patient__c = techHexalisDossierImport.Code_Patient__c,
                    Adresse_Patient__c = techHexalisDossierImport.Adresse_Patient__c,
                    Code_Civilite__c = techHexalisDossierImport.Code_Civilite__c,
                    Code_Espece_Patient__c = techHexalisDossierImport.Code_Espece_Patient__c,
                    Code_Genre_Patient__c = techHexalisDossierImport.Code_Genre_Patient__c,
                    Code_Postal_Patient__c = techHexalisDossierImport.Code_Postal_Patient__c,
                    Code_Prescripteur__c = techHexalisDossierImport.Code_Prescripteur__c,
                    Date_Creation_Hexalis__c = Date.valueOf(techHexalisDossierImport.Date_Creation_Dossier__c),
                    Date_Naissance_Patient__c = techHexalisDossierImport.Date_Naissance_Patient__c != null ? Date.valueOf(techHexalisDossierImport.Date_Naissance_Patient__c) : null,
                    Date_Prelevement__c = techHexalisDossierImport.Date_Prelevement__c != null ? Date.valueOf(techHexalisDossierImport.Date_Prelevement__c) : null,
                    EffectiveDate = Date.valueOf(techHexalisDossierImport.Date_Creation_Dossier__c),
                    Email_Patient__c = techHexalisDossierImport.Email_Patient__c,
                    IDDossier__c = dossierId,
                    Lib_Espece_Patient__c = techHexalisDossierImport.Lib_Espece_Patient__c,
                    Lib_Genre_Patient__c = techHexalisDossierImport.Lib_Genre_Patient__c,
                    Mobile_Patient__c = techHexalisDossierImport.Mobile_Patient__c,
                    Nom_Patient__c = techHexalisDossierImport.Nom_Patient__c,
                    Animal_Name__c = techHexalisDossierImport.Prenom_Patient__c,
                    Animal_Owner_Name__c = techHexalisDossierImport.Nom_Patient__c,
                    Numero__c = techHexalisDossierImport.Numero__c,
                    Prenom_Patient__c = techHexalisDossierImport.Prenom_Patient__c,
                    Solde__c = techHexalisDossierImport.Solde__c,
                    Statut__c = techHexalisDossierImport.Statut__c,
                    Tel_Patient__c = techHexalisDossierImport.Tel_Patient__c,
                    Ville_Patient__c = techHexalisDossierImport.Ville_Patient__c,
                    Tech_Ext_Id__c = techId,
                    RecordTypeId = rtId,
                    Message_Integration_Hexalis__c = informationDossier.atelReason,
                    Status = STATUS_DRAFT,
                    Pricebook2Id = pricebookId,
                    Conditions_de_Reglement_Cerbavet__c = accountToConsider.Conditions_de_Reglement_Cerbavet__c,
                    Statut_Compte_Rendu__c = 'Non',
                    Facturable__c = facturable,
                    blng__BillingAccount__c = informationDossier.billingAccountId,
                    BillingCountry = accountToConsider.BillingCountry
            );

            ordersToCreate.add(order);

            Map<String, CV_OrderCreationService.PricingInfo> infosPricing = pricesByCodeExamsByDossiersIds.get(dossierId);

            System.debug('========================== CV_OrderCreationBatch infosPricing: ' + infosPricing);

            Map<String, Map<String, Decimal>> pricebookPricesByCurrencyByProductCodes = cvOrderCreationService.getPricebookPricesByCurrencyByProductCodesByPricebookIds().containsKey(pricebookId) ?
                    cvOrderCreationService.getPricebookPricesByCurrencyByProductCodesByPricebookIds().get(pricebookId) : new Map<String, Map<String, Decimal>>();
            Map<String, Map<String, Id>> priceBookEntryIdsByCurrencyByProductCodes = cvOrderCreationService.getPriceBookEntryIdsByCurrencyByProductCodesByPricebookIds().containsKey(pricebookId) ?
                    cvOrderCreationService.getPriceBookEntryIdsByCurrencyByProductCodesByPricebookIds().get(pricebookId) : new Map<String, Map<String, Id>>();

            System.debug('========================== CV_OrderCreationBatch infosPricing priceBookEntryIdsByCurrencyByProductCodes: ' + priceBookEntryIdsByCurrencyByProductCodes);
            System.debug('========================== CV_OrderCreationBatch infosPricing pricebookPricesByCurrencyByProductCodes: ' + pricebookPricesByCurrencyByProductCodes);

            for (String examCode : infosPricing.keySet()) {
                CV_OrderCreationService.PricingInfo pricing = infosPricing.get(examCode);
                System.debug('========================== CV_OrderCreationBatch infosPricing examCode: ' + examCode);
                System.debug('========================== CV_OrderCreationBatch infosPricing CV_OrderCreationService.knownExamCodes.contains(examCode): ' + cvOrderCreationService.getKnownExamCodes().contains(examCode));

//                String codeExamen = (pricing.productId != null && CV_OrderCreationService.priceBookEntryIdsByCurrencyByProductCodes.containsKey(examCode) && CV_OrderCreationService.knownExamCodes.contains(examCode)) ? examCode : ATEL_CODE;
//                Id pricebookEntryId = CV_OrderCreationService.priceBookEntryIdsByCurrencyByProductCodes.get(codeExamen).get(accountToConsider.CurrencyIsoCode);

                String codeExamen = (pricing.productId != null && priceBookEntryIdsByCurrencyByProductCodes.containsKey(examCode) && cvOrderCreationService.getKnownExamCodes().contains(examCode)) ? examCode : ATEL_CODE;
                System.debug('========================== CV_OrderCreationBatch infosPricing codeExamen: ' + codeExamen);

                Id pricebookEntryId = priceBookEntryIdsByCurrencyByProductCodes.get(codeExamen).get(accountToConsider.CurrencyIsoCode);

                OrderItem orderItem = new OrderItem(
                        ListPrice = codeExamen == ATEL_CODE ? 0 : pricing.basePrice,
                        UnitPrice =  codeExamen == ATEL_CODE ? 0 : pricing.unitPrice,
                        Quantity = 1,
                        Code_produit_Hexalis__c = examCode,
                        Product2Id = (pricing.productId != null && codeExamen != ATEL_CODE) ? pricing.productId : atelProductId,
                        Order = new Order (Tech_Ext_Id__c = techId),
                        PricebookEntryId = pricebookEntryId,
                        SBQQ__ChargeType__c = 'One-Time',
                        blng__NextBillingDate__c = Date.today(),
                        blng__NextChargeDate__c = Date.today(),
                        blng__InvoiceRunProcessingStatus__c = 'Pending Billing',
                        blng__InvoiceRunStatusIndex__c = 'Pending Billing'
                );

                orderItemsToCreate.add(orderItem);
            }

        }

        if (!ordersToCreate.isEmpty()) {

            SBQQ.TriggerControl.disable();

            System.debug('========================== CV_OrderCreationBatch ordersToCreate: ' + ordersToCreate);
            System.debug('========================== CV_OrderCreationBatch orderItemsToCreate: ' + orderItemsToCreate);
            Database.SaveResult[] resultsCn = Database.insert(ordersToCreate, false);
            Database.SaveResult[] resultsCnLines = Database.insert(orderItemsToCreate, false);

            System.debug('========================== CV_OrderCreationBatch resultsCnLines: ' + resultsCnLines);

            List<Tech_Hexalis_Dossier_Import__c> techHexalisDossierImportsInError = new List<Tech_Hexalis_Dossier_Import__c>();

            try {
                for (Integer i=0; i < resultsCn.size(); i++) {
                    Database.SaveResult sr = resultsCn[i];
                    if (!sr.isSuccess()) {
                        String techHexalisId = ordersToCreate[i].Tech_Ext_Id__c.split('-')[0];

                        String message = '';
                        for(Database.Error err : sr.getErrors()) { message += '|' + err.getMessage(); }

                        techHexalisDossierImportsInError.add(new Tech_Hexalis_Dossier_Import__c(Id = techHexalisId, Statut_Traitement__c = 'Erreur', Error_Message__c = message));

                    } else {
                        String dossierId = ordersToCreate[i].IDDossier__c;
                        ordersToSendForTransport.put(ordersToCreate[i].IDDossier__c, sr.getId());
                        dossiersToDelete.add(dossierId);
                    }
                }

            } catch (Exception e) {
                System.debug('============================= ERROR CV_OrderCreationBatch: ' + e.getMessage());
            }

            if (!techHexalisDossierImportsInError.isEmpty()) {
                update techHexalisDossierImportsInError;
            }

//            SBQQ.TriggerControl.enable();

            if (!dossiersToDelete.isEmpty()) {
                List<Tech_Hexalis_Dossier_Import__c> techHexalisDossierImportsToDelete = new List<Tech_Hexalis_Dossier_Import__c>([SELECT Id, Statut_Traitement__c FROM Tech_Hexalis_Dossier_Import__c WHERE Code_Dossier__c in :dossiersToDelete]);
                List<Tech_Hexalis_Order_Import__c> techHexalisOrderImportsToDelete = new List<Tech_Hexalis_Order_Import__c>([SELECT Id FROM Tech_Hexalis_Order_Import__c WHERE Code_Dossier__c in :dossiersToDelete]);

                System.debug('========================== CV_OrderCreationBatch FINISH techHexalisOrderImportsToDelete: ' + techHexalisOrderImportsToDelete);
                System.debug('========================== CV_OrderCreationBatch FINISH techHexalisDossierImportsToDelete: ' + techHexalisDossierImportsToDelete);

                if (batchSettings.Keep_Records__c) {
                    for (Tech_Hexalis_Dossier_Import__c techHexalisDossierImport : techHexalisDossierImportsToDelete) {
                        techHexalisDossierImport.Statut_Traitement__c = STATUS_TREATED;
                    }
                    update techHexalisDossierImportsToDelete;

                } else {
                    delete techHexalisOrderImportsToDelete;
                    delete techHexalisDossierImportsToDelete;
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {

        SBQQ.TriggerControl.disable();

        Map<String, CV_OrderCreationService.TransportInfo> transportInfosByCorrespondantIds = cvOrderCreationService.getTransportInfosByCorrespondantIds();

        if (!transportInfosByCorrespondantIds.isEmpty()) {

            Map<Id, Order> ordersByIds = new Map<Id, Order>([SELECT Id, Pricebook2Id, Tech_Ext_Id__c FROM Order WHERE Id in :ordersToSendForTransport.values()]);
            Map<Id, Account> accountsByIds = new Map<Id, Account>([SELECT Id, Facturation_coursier__c, Facturation_coursier_reduit__c, CurrencyIsoCode FROM Account WHERE Id in :transportInfosByCorrespondantIds.keySet()]);
            Product2 product2 = [SELECT Id FROM Product2 WHERE ProductCode = :System.Label.CV_SPEC_TRAN_PRD];
            List<OrderItem> orderItemsToCreate = new List<OrderItem>();

            Set<String> activationToRemove = new Set<String>();

            for (String accountId : transportInfosByCorrespondantIds.keySet()) {
                CV_OrderCreationService.TransportInfo transportInfo = transportInfosByCorrespondantIds.get(accountId);

                String orderId = ordersToSendForTransport.get(transportInfo.firstTechDossier);
                Order order = ordersByIds.get(orderId);
                Account account = accountsByIds.get(accountId);

                System.debug('====================================== NEW NEW NEW CV_OrderCreationBatch finish order: ' + order);

                Map<String, Map<String, Id>> priceBookEntryIdsByCurrencyByProductCodes = cvOrderCreationService.getPriceBookEntryIdsByCurrencyByProductCodesByPricebookIds().get(order.Pricebook2Id);

                if (priceBookEntryIdsByCurrencyByProductCodes != null) {

                    Decimal price = transportInfo.nbrDossier > 1 ? account.Facturation_coursier_reduit__c : account.Facturation_coursier__c;
                    Id productId = product2.Id;
                    Id pricebookId = priceBookEntryIdsByCurrencyByProductCodes.get(System.Label.CV_SPEC_TRAN_PRD).get(account.CurrencyIsoCode);

                    System.debug('====================================== NEW NEW NEW CV_OrderCreationBatch finish price: ' + price);
                    if (price == null) {
                        price = 0;
                        productId = atelProductId;
                        activationToRemove.add(order.Tech_Ext_Id__c);
                        pricebookId = priceBookEntryIdsByCurrencyByProductCodes.get(ATEL_CODE).get(account.CurrencyIsoCode);
                    }

                    OrderItem orderItem = new OrderItem(
                            ListPrice = 0,
                            UnitPrice =  price,
                            Quantity = 1,
                            Code_produit_Hexalis__c = System.Label.CV_SPEC_TRAN_PRD,
                            Product2Id = productId,
                            OrderId = order.Id,
                            PricebookEntryId = pricebookId,
                            SBQQ__ChargeType__c = 'One-Time',
                            blng__NextBillingDate__c = Date.today(),
                            blng__NextChargeDate__c = Date.today(),
                            blng__InvoiceRunProcessingStatus__c = 'Pending Billing',
                            blng__InvoiceRunStatusIndex__c = 'Pending Billing'
                    );

                    orderItemsToCreate.add(orderItem);
                }
            }
            ordersToSendForActivation.removeAll(activationToRemove);
            System.debug('====================================== NEW NEW NEW CV_OrderCreationBatch finish orderItemsToCreate: ' + orderItemsToCreate);
            System.debug('====================================== NEW NEW NEW CV_OrderCreationBatch finish ordersToSendForActivation: ' + ordersToSendForActivation);

            if (!orderItemsToCreate.isEmpty()) {
                insert orderItemsToCreate;
            }
        }


        //Activated Orders which need to be activated
        List<Order> ordersToUpdate = new List<Order>();
        for (String techId : ordersToSendForActivation) {
            ordersToUpdate.add(new Order(Tech_Ext_Id__c = techId, Status = STATUS_ACTIVATED));
        }

        if (!Test.isRunningTest()) { SBQQ.TriggerControl.enable(); }

        if (!ordersToUpdate.isEmpty()) {
            Schema.SObjectField ftoken = Order.Fields.Tech_Ext_Id__c;
            List<Database.UpsertResult> upsertResults = Database.upsert(ordersToUpdate, ftoken, false);

            List<Order> ordersInError = new List<Order>();
            Set<Id> activatedOrderIds = new Set<Id>();
            for (Integer i=0; i < upsertResults.size(); i++) {
                Database.UpsertResult ur = upsertResults[i];
                if (!ur.isSuccess()) {
                    String errorMsg = ur.getErrors()[0].getMessage() != null && ur.getErrors()[0].getMessage().length() > 255 ? ur.getErrors()[0].getMessage().substring(0, 255) : ur.getErrors()[0].getMessage();
                    ordersInError.add(new Order(Id = ur.Id, Message_Integration_Hexalis__c = errorMsg));
                } else {
                    activatedOrderIds.add(ur.Id);
                }
            }
            System.debug('========================== CV_OrderCreationBatch FINISH ordersInError: ' + ordersInError);
            if (!ordersInError.isEmpty()) {
                update ordersInError;
            }

            if (!activatedOrderIds.isEmpty()) {
                List<OrderItem> orderItems = new List<OrderItem>([SELECT Id, SBQQ__Status__c, SBQQ__Activated__c, blng__NextBillingDate__c, blng__InvoiceRunProcessingStatus__c FROM OrderItem WHERE OrderId in :activatedOrderIds]);

                for (OrderItem oi : orderItems) {
                    oi.SBQQ__Status__c = 'Activated';
                    oi.SBQQ__Activated__c = true;
                }
                update orderItems;
            }
        }


        System.debug('========================== CV_OrderCreationBatch FINISH ');


    }

    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        if(batchSettings.Active__c) {
            CV_OrderCreationBatch batch = new CV_OrderCreationBatch();
            Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));
        }
    }
}