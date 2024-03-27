/**
 * @description       : Classe service autour de le création des commandes
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 19-04-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_OrderCreationService {

    private Set<String> decreasingPriceProductCodes;
    private Set<String> nonDiscountableProductCodes;
    private Set<String> irrelevantCodes;
    private Set<String> knownExamCodes;
//    public static Id pricebookId;

    private List<String> orderedBundleCodes;
//    public static Set<String> addedBundles = new Set<String>();
    private Map<String, List<String>> productCodesByBundleCodes;
    private Map<String, List<CV_Order_Add_Codes__mdt>> productCodesByAccountFilters;
    private Map<String, List<String>> mandatoryBundleLinesByBundleNames;
    private Map<String, Decimal> extraDiscountByExamCodes;
    private Map<Integer, Decimal> degressiveDiscountByNumberOfProducts;
    private Map<String, Id> productIdsByHexalisCodes;
    private Map<String, Map<String, Map<String, Id>>> priceBookEntryIdsByCurrencyByProductCodesByPricebookIds;
    private Map<String, Map<String, Map<String, Decimal>>> pricebookPricesByCurrencyByProductCodesByPricebookIds;
    private Map<String, String> pricebookIdsByCountries;
    private String defaultPricebook;
    private Set<String> configuredPricebooks;
    private Map<String, TransportInfo> transportInfosByCorrespondantIds;

    private List<String> atelCodes = System.Label.CV_Atel_Codes == null ? new List<String>() : System.Label.CV_Atel_Codes.split(',');

    private static final String STATUS_DRAFT = 'Draft';


    public CV_OrderCreationService() {
        loadCodeInformation();
        loadProductInformation();
        loadPriceBookMapping();
        loadPriceBookEntries();
        loadDegressivePrice();

        transportInfosByCorrespondantIds = new Map<String, TransportInfo>();

    }

    public Map<String, Map<String, Map<String, Decimal>>> getPricebookPricesByCurrencyByProductCodesByPricebookIds() {
        return pricebookPricesByCurrencyByProductCodesByPricebookIds;

    }

    public Map<String, Map<String, Map<String, Id>>> getPriceBookEntryIdsByCurrencyByProductCodesByPricebookIds() {
        return priceBookEntryIdsByCurrencyByProductCodesByPricebookIds;
    }

    public Set<String> getKnownExamCodes() {
        return knownExamCodes;
    }

    public Map<String, TransportInfo> getTransportInfosByCorrespondantIds() {
        return transportInfosByCorrespondantIds;
    }

//    public void loadPricingInformation() {
//
//        loadPriceBookMapping();
//        loadPriceBookEntries();
//        loadDegressivePrice();
//
//    }

    public void loadCodeInformation() {

        irrelevantCodes = new Set<String>();
        mandatoryBundleLinesByBundleNames = new Map<String, List<String>>();
        productCodesByAccountFilters = new Map<String, List<CV_Order_Add_Codes__mdt>>();

        if (knownExamCodes == null) { knownExamCodes = new Set<String>(); }

        for (Hexalis_Code_Non_Pertinent__mdt nonPertinent : [SELECT Code__c FROM Hexalis_Code_Non_Pertinent__mdt]) {
            irrelevantCodes.add(nonPertinent.Code__c);
        }

        knownExamCodes.addAll(irrelevantCodes);
        System.debug('============================== CV_OrderCreationService loadCodeInformation irrelevantCodes: ' + irrelevantCodes);

        for (Hexalis_Specific_Bundle_Behavior__mdt bundleBehavior : [SELECT Bilan__c, Code_Obligatoire__c FROM Hexalis_Specific_Bundle_Behavior__mdt]) {

            List<String> mandatoryCodes = bundleBehavior.Code_Obligatoire__c.split(',');
            mandatoryBundleLinesByBundleNames.put(bundleBehavior.Bilan__c, mandatoryCodes);

        }
        System.debug('============================== CV_OrderCreationService loadCodeInformation mandatoryBundleLinesByBundleNames: ' + mandatoryBundleLinesByBundleNames);

        extraDiscountByExamCodes = new Map<String, Decimal>();
        for (Hexalis_Discount_Code__mdt hexalisDiscountCode : [SELECT Code__c, Discount__c FROM Hexalis_Discount_Code__mdt]) {
            extraDiscountByExamCodes.put(hexalisDiscountCode.Code__c, hexalisDiscountCode.Discount__c);
        }
        System.debug('============================== CV_OrderCreationService loadCodeInformation extraDiscountByExamCodes: ' + extraDiscountByExamCodes);

        //MCA 28/12/2022 FFD8
        for (CV_Order_Add_Codes__mdt orderAddCodes : [
                SELECT Product_Code__c, Account_Filter__c, Exclude_If_Code__c, Only_If_Code_Present__c
                FROM CV_Order_Add_Codes__mdt
                WHERE Active__c = true AND Activation_Date__c <= :Date.today()]) {
            if (!productCodesByAccountFilters.containsKey(orderAddCodes.Account_Filter__c)) {
                productCodesByAccountFilters.put(orderAddCodes.Account_Filter__c, new List<CV_Order_Add_Codes__mdt>());
            }
            List<CV_Order_Add_Codes__mdt> codes = productCodesByAccountFilters.get(orderAddCodes.Account_Filter__c);
            codes.add(orderAddCodes);
        }
        System.debug('============================== CV_OrderCreationService loadCodeInformation productCodesByAccountFilters: ' + productCodesByAccountFilters);

    }

    public void loadProductInformation() {

        productCodesByBundleCodes = new Map<String, List<String>>();
        decreasingPriceProductCodes = new Set<String>();
        nonDiscountableProductCodes = new Set<String>();
        productIdsByHexalisCodes = new Map<String, Id>();
        orderedBundleCodes = new List<String>();

        List<String> tempOrderedBundleCodes = new List<String>();

        if (knownExamCodes == null) { knownExamCodes = new Set<String>(); }


        List<Product2> productsToHandle = new List<Product2>([
                SELECT Id, ProductCode, SBQQ__NonDiscountable__c, Prix_Degressif__c,
                (SELECT Id, SBQQ__ProductCode__c FROM SBQQ__Options__r)
                FROM Product2
                WHERE IsActive = TRUE]);

        for (Product2 product : productsToHandle) {

            knownExamCodes.add(product.ProductCode);
            productIdsByHexalisCodes.put(product.ProductCode, product.Id);
            Integer index = 0;

            if (product.SBQQ__Options__r != null && !product.SBQQ__Options__r.isEmpty()) {

                if (!productCodesByBundleCodes.containsKey(product.ProductCode)) {
                    productCodesByBundleCodes.put(product.ProductCode, new List<String>());

                }
                List<String> productCodes = productCodesByBundleCodes.get(product.ProductCode);

                for (SBQQ__ProductOption__c productOption : product.SBQQ__Options__r) {
//                    if (product.ProductCode != productOption.SBQQ__ProductCode__c) {
                        productCodes.add(productOption.SBQQ__ProductCode__c);
                        index++;
//                    }
                }
                String keyPrefix = String.valueOf(product.SBQQ__Options__r.size()).leftPad(3, '0') + '_' + product.ProductCode;
                tempOrderedBundleCodes.add(keyPrefix);
            }

            if (product.Prix_Degressif__c) {
                decreasingPriceProductCodes.add(product.ProductCode);
            }
            if (product.SBQQ__NonDiscountable__c) {
                nonDiscountableProductCodes.add(product.ProductCode);
            }
        }

        System.debug('============================== CV_OrderCreationService loadProductInformation nonDiscountableProductCodes: ' + nonDiscountableProductCodes);
        System.debug('============================== CV_OrderCreationService loadProductInformation decreasingPriceProductCodes: ' + decreasingPriceProductCodes);

        tempOrderedBundleCodes.sort();

        for (integer i = tempOrderedBundleCodes.size(); i >= 1; i--) {
            orderedBundleCodes.add(tempOrderedBundleCodes[i-1]);

        }

        System.debug('============================== CV_OrderCreationService loadProductInformation orderedBundleCodes: ' + orderedBundleCodes);

    }

    public Map<String, Tech_Hexalis_Dossier_Import__c> getDossierInfosByCodeDossiers(List<Tech_Hexalis_Dossier_Import__c> dossierImports) {

        Map<String, Tech_Hexalis_Dossier_Import__c> dossierInfosByCodeDossiers = new Map<String, Tech_Hexalis_Dossier_Import__c>();

        for (Tech_Hexalis_Dossier_Import__c techHexalisDossierImport : dossierImports) {
            dossierInfosByCodeDossiers.put(techHexalisDossierImport.Code_Dossier__c, techHexalisDossierImport);
        }

        System.debug('============================== CV_OrderCreationService getDossierInfosByCodeDossiers dossierInfosByCodeDossiers: ' + dossierInfosByCodeDossiers);

        return dossierInfosByCodeDossiers;

    }

    public Map<String, List<Tech_Hexalis_Order_Import__c>> getExamenInfosByCodeDossiers(List<Tech_Hexalis_Dossier_Import__c> dossierImports) {

        Map<String, List<Tech_Hexalis_Order_Import__c>> examenInfosByCodeDossiers = new Map<String, List<Tech_Hexalis_Order_Import__c>>();

        Set<String> dossierNumbers = new Set<String>();

        for (Tech_Hexalis_Dossier_Import__c dossierImport : dossierImports) {
            dossierNumbers.add(dossierImport.Code_Dossier__c);
        }

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Tech_Hexalis_Order_Import__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' FROM Tech_Hexalis_Order_Import__c';
        query += ' WHERE Code_Dossier__c in :dossierNumbers';
        query += ' ORDER BY Code_Dossier__c';


        for (Tech_Hexalis_Order_Import__c orderImport : (List<Tech_Hexalis_Order_Import__c>)Database.query(query))  {
            if (!examenInfosByCodeDossiers.containsKey(orderImport.Code_Dossier__c)) {
                examenInfosByCodeDossiers.put(orderImport.Code_Dossier__c, new List<Tech_Hexalis_Order_Import__c>());
            }

            List<Tech_Hexalis_Order_Import__c> orderImports = examenInfosByCodeDossiers.get(orderImport.Code_Dossier__c);
            orderImports.add(orderImport);

        }

        System.debug('============================== CV_OrderCreationService getExamenInfosByCodeDossiers examenInfosByCodeDossiers: ' + examenInfosByCodeDossiers);

        return examenInfosByCodeDossiers;

    }

    public Map<String, InformationDossier>
    getCleanedInformationDossiers (Map<String, String> accountCodesByDossierIds, Map<String, List<String>> examCodesByDossierIds, Map<String, Tech_Hexalis_Order_Import__c> mainTechInfosByDossiersIds) {

        System.debug('============================== CV_OrderCreationService cleanExamEntries examCodesByDossierIds: ' + examCodesByDossierIds);

        Map<String, InformationDossier> cleanedInformationDossiers = new Map<String, InformationDossier>();

        Map<String, Account> accountsByHexalisCodes = getAccountsByHexalisCodes(new Set<String>(accountCodesByDossierIds.values()));

        Map<Id, Id> accountN2IdsBySGLIds = new Map<Id,Id>();
        for (Account sglAccount : accountsByHexalisCodes.values()) {
            getAccountsParentN2(sglAccount, accountN2IdsBySGLIds, sglAccount);
        }
        System.debug('============================== CV_OrderCreationService getCleanedInformationDossiers accountN2IdsBySGLIds: ' + accountN2IdsBySGLIds);

        Set<String> bundleList = productCodesByBundleCodes.keySet();
        System.debug('============================== CV_OrderCreationService getCleanedInformationDossiers bundleList: ' + bundleList);

        for (String dossierId : examCodesByDossierIds.keySet()) {
            System.debug('============================== CV_OrderCreationService getCleanedInformationDossiers dossierId: ' + dossierId);

            Account account = accountsByHexalisCodes.get(accountCodesByDossierIds.get(dossierId));
            System.debug('============================== CV_OrderCreationService getCleanedInformationDossiers account: ' + account);
            Id billingAccountId = account != null ? accountN2IdsBySGLIds.get(account.Id) : null;
            System.debug('============================== CV_OrderCreationService getCleanedInformationDossiers billingAccountId: ' + billingAccountId);

            List<String> examCodesOrigin = examCodesByDossierIds.get(dossierId);
            System.debug('============================== CV_OrderCreationService cleanExamEntries examCodesOrigin: ' + examCodesOrigin);
            System.debug('============================== CV_OrderCreationService cleanExamEntries examCodesOrigin #: ' + examCodesOrigin.size());

            Boolean hasAtelCodes = false;

            if (examCodesOrigin != null && !examCodesOrigin.isEmpty()) {

                List<String> codesToKeep = removeIrrelevantCodes(examCodesOrigin);
                System.debug('============================== CV_OrderCreationService cleaned irrelevant codesToKeep : ' + codesToKeep);

                List<String> cleanedExams = cleanExamsLineBasedOnBundles(codesToKeep, productCodesByBundleCodes.keySet());

                System.debug('============================== CV_OrderCreationService cleanExamEntries cleanedExams: ' + cleanedExams);
                System.debug('============================== CV_OrderCreationService cleanExamEntries cleanedExams #: ' + cleanedExams.size());

                List<String> cleanedBundles = addBundleLinesBasedOnCodesCombo(cleanedExams);

                System.debug('============================== CV_OrderCreationService cleanExamEntries cleanedBundles after add bundle: ' + cleanedBundles);
                System.debug('============================== CV_OrderCreationService cleanExamEntries cleanedBundles after add bundle #: ' + cleanedBundles.size());

                String atelReason;
                Decimal extraPourcentage = 0;
                for (String code : cleanedBundles) {
                    if (extraDiscountByExamCodes.containsKey(code)) {
                        extraPourcentage += extraDiscountByExamCodes.get(code);
                    }

                    if (atelCodes.contains(code) ) {

                        hasAtelCodes = true;
                        atelReason = 'Code ATEL Présent';

                    } else if ( !knownExamCodes.contains(code)) {

                        hasAtelCodes = true;
                        atelReason = 'Présence d\'un code examen inconnu: ' + code;

                    } else if ( account == null) {
                        hasAtelCodes = true;
                        atelReason = 'Code correspondant inconnu: ' + accountCodesByDossierIds.get(dossierId);
                    }
                }

                //MCA 28/12/2022 FFD8 - MODIFIED 13/02/2023
                if (account != null) {
                    cleanedBundles.addAll(additionalCodesToAdd(examCodesOrigin, account.Conditions_de_Reglement_Cerbavet__c, account, dossierId));
                    String extraCheck = 'deposelabo' + account.Depose_Labo__c;
                    System.debug('============================== CV_OrderCreationService deposelabo: ' + extraCheck);
                    cleanedBundles.addAll(additionalCodesToAdd(examCodesOrigin, extraCheck, account, dossierId));
                }

//                if (account != null) {
//                    List<String> codesToAdd = productCodesByAccountFilters.get(account.Conditions_de_Reglement_Cerbavet__c);
//                    if (codesToAdd != null) {
//                        cleanedBundles.addAll(codesToAdd);
//                    }
//                }

                String pricebookId = account != null ? getPricebookId(account.BillingCountry) : null;
                cleanedInformationDossiers.put(dossierId,
                        new InformationDossier(
                                dossierId,
                                cleanedBundles,
                                hasAtelCodes,
                                atelReason,
                                extraPourcentage,
                                account,
                                mainTechInfosByDossiersIds.get(dossierId),
                                billingAccountId,
                                pricebookId
                        ));

            }
        }

        return cleanedInformationDossiers;
    }

    private List<String> additionalCodesToAdd(List<String> originCodes, String filterdValue, Account account, String dossierId) {

        List<String> codesToAddList = new List<String>();

        List<CV_Order_Add_Codes__mdt> codesToAdd = productCodesByAccountFilters.get(filterdValue);
        if (codesToAdd != null) {

            for (CV_Order_Add_Codes__mdt cvOrderAddCodes : codesToAdd) {
                Boolean toExclude = false;
                List<String> excludedCodes = cvOrderAddCodes.Exclude_If_Code__c != null ? cvOrderAddCodes.Exclude_If_Code__c.split(';') : null;

                if (excludedCodes != null) {
                    for (String excludeCode : excludedCodes) {
                        if (originCodes.contains(excludeCode)) {
                            toExclude = true;
                            break;
                        }
                    }
                }
                if (!toExclude) {
                    if (cvOrderAddCodes.Only_If_Code_Present__c == null || (cvOrderAddCodes.Only_If_Code_Present__c != null && originCodes.contains(cvOrderAddCodes.Only_If_Code_Present__c))) {

                        if (cvOrderAddCodes.Product_Code__c == System.Label.CV_SPEC_TRAN_PRD) {
                            if (!transportInfosByCorrespondantIds.containsKey(account.Id)) {
                                transportInfosByCorrespondantIds.put(account.Id, new TransportInfo(dossierId));

                            } else {
                                TransportInfo transportInfo = transportInfosByCorrespondantIds.get(account.Id);
                                transportInfo.nbrDossier = transportInfo.nbrDossier + 1;
                            }
                        // TMA_0010 15/02/24 LBA
                        } else if (cvOrderAddCodes.Product_Code__c == System.Label.CV_SPEC_GESTION_DOSSIER) {
                            if(!Account.Exoneration_Frais_de_Gestion__c){
                                codesToAddList.add(cvOrderAddCodes.Product_Code__c);
                            }
                        } else {
                            codesToAddList.add(cvOrderAddCodes.Product_Code__c);
                        }
                    }
                }
            }
        }
        System.debug('============================== CV_OrderCreationService additionalCodesToAdd codesToAddList: ' + codesToAddList);

        return codesToAddList;

    }

    /**
    * Remove all irrelevant exam code lines
    * @param examLineCodes Code exam line for a specific dossier
    */
    private List<String> removeIrrelevantCodes(List<String> examLineCodes) {

        if (examLineCodes == null || examLineCodes.isEmpty()) { return null; }

        List<String> codesTokeep = examLineCodes.clone();

        for (String examCode : examLineCodes) {
            if (irrelevantCodes.contains(examCode.toUpperCase())) {
                Integer index = codesTokeep.indexOf(examCode);
                codesTokeep.remove(index);
            }
        }

        return codesTokeep;
    }

    /**
    * Add bundles line if combo of lines mathcing bundle is found
    * @param examLineCodes Code exam line for a specific dossier
    */
    private List<String> addBundleLinesBasedOnCodesCombo(List<String> examLineCodes) {

        Set<String> addedBundles = new Set<String>();
        Set<String> excludedCodes = new Set<String>();

        System.debug('============================== CV_OrderCreationService addBundleLinesBasedOnCodesCombo orderedBundleCode: ' + orderedBundleCodes);

//        for (String bundleCode : productCodesByBundleCodes.keySet()) {
        for (String bundleOrderedCode : orderedBundleCodes) {

            String bundleCode = bundleOrderedCode.split('_')[1];
//            System.debug('============================== CV_OrderCreationService addBundleLinesBasedOnCodesCombo bundleCode: ' + bundleCode);

            List<String> bundleComposition = productCodesByBundleCodes.get(bundleCode);
            List<String> mandatoryCodes = mandatoryBundleLinesByBundleNames.get(bundleCode);

            Boolean mandatoryFound = false;
            Boolean atLeastOtherLineFound = false;

//            System.debug('============================== CV_OrderCreationService addBundleLinesBasedOnCodesCombo bundleComposition init: ' + bundleComposition);
            if (bundleComposition != null && !bundleComposition.isEmpty()) {
                List<String> tempBundleComposition = bundleComposition.clone();
//                Integer indexSameCode = tempBundleComposition.indexOf(bundleCode);

//                if (indexSameCode != -1) {
//                    tempBundleComposition.remove(indexSameCode);
//                }

                for (String examCode : examLineCodes) {
                    Integer index = tempBundleComposition.indexOf(examCode);

                    if (!addedBundles.contains(examCode) && !excludedCodes.contains(examCode)) {
                        if (mandatoryCodes != null) {  // Treat specific bundles where only the mandatory line is needed + any other line to apply the bundle
                            if (mandatoryCodes.contains(examCode)) {
                                mandatoryFound = true;

                            } else if (index != -1) {
                                atLeastOtherLineFound = true;

                            }
                        }

                        if (index != -1) {
                            tempBundleComposition.remove(index);
                        }
                    }
                }
//                System.debug('============================== CV_OrderCreationService addBundleLinesBasedOnCodesCombo bundleComposition: ' + bundleComposition);
                if (tempBundleComposition.isEmpty() || (mandatoryFound && atLeastOtherLineFound)) {
                    System.debug('============================== CV_OrderCreationService addBundleLinesBasedOnCodesCombo adding bundle code: ' + bundleCode);
                    examLineCodes.add(bundleCode);
                    addedBundles.add(bundleCode);
                    excludedCodes.addAll(bundleComposition);

                }
            }
        }

        System.debug('============================== CV_OrderCreationService addBundleLinesBasedOnCodesCombo addedBundles: ' + addedBundles);
        if (!addedBundles.isEmpty()) {
            return cleanExamsLineBasedOnBundles(examLineCodes, addedBundles);
        } else {
            return examLineCodes;
        }
    }

    /**
    * Remove line included in bundles to keep only the bundle lines
    * @param examLineCodes Code exam lines for a specific dossier
    * @param bundlesToClean list of bundles codes for which lines need to be cleaned
    * @return list of cleaned exam codes
    */
    private List<String> cleanExamsLineBasedOnBundles(List<String> examLineCodes, Set<String> bundlesToClean) {

        System.debug('============================== CV_OrderCreationService cleanExamsLineBasedOnBundles bundlesToClean: ' + bundlesToClean);

        Set<String> bundleCodesToCleanup = new Set<String>();

        List<String> codesToKeep = examLineCodes.clone();

        for (String codeOrigin : examLineCodes) {
            if (bundlesToClean.contains(codeOrigin)) {
                bundleCodesToCleanup.add(codeOrigin);
            }
        }

        System.debug('============================== CV_OrderCreationService cleanExamsLineBasedOnBundles bundleCodesToCleanup: ' + bundleCodesToCleanup);

        if (!bundleCodesToCleanup.isEmpty()) {
            for (String bundleCodeToClean : bundleCodesToCleanup) {
                List<String> bundleCodes = productCodesByBundleCodes.get(bundleCodeToClean);
                System.debug('============================== CV_OrderCreationService cleanExamsLineBasedOnBundles bundleCodes: ' + bundleCodes);

                for (String bundleCode : bundleCodes) {
                    System.debug('============================== CV_OrderCreationService cleanExamsLineBasedOnBundles bundleCode: ' + bundleCode);
                    Integer indexOfCode = codesToKeep.indexOf(bundleCode);
                    if ((bundleCode != bundleCodeToClean) && (indexOfCode != -1)) {
                        codesToKeep.remove(indexOfCode);
                    }
                }
            }
        }

        System.debug('============================== CV_OrderCreationService cleanExamsLineBasedOnBundles codesToKeep: ' + codesToKeep);
        System.debug('============================== CV_OrderCreationService cleanExamsLineBasedOnBundles codesToKeep # : ' + codesToKeep.size());
        return codesToKeep;

    }

    private void loadDegressivePrice() {

        degressiveDiscountByNumberOfProducts = new Map<Integer, Decimal>();

        for (CV_Prix_Degressif__mdt prixDegressif : [SELECT LowerBound__c, UpperBound__c, Discount__c FROM CV_Prix_Degressif__mdt ORDER BY LowerBound__c]) {
            for (Integer i = (Integer)prixDegressif.LowerBound__c; i <= (Integer)prixDegressif.UpperBound__c; i++) {
                degressiveDiscountByNumberOfProducts.put(i, prixDegressif.Discount__c);
            }
        }

        System.debug('============================== CV_OrderCreationService loadDegressivePrice codiscountByNumberOfProductsdesToKeep: ' + degressiveDiscountByNumberOfProducts);

    }

    private void loadPriceBookMapping() {

        pricebookIdsByCountries = new Map<String, String>();
        configuredPricebooks = new Set<String>();

        Map<String, Id> pricebookIdsByNames = new Map<String, Id>();
        List<CV_Pricebook_Mapping__mdt> pricebookMappings = new List<CV_Pricebook_Mapping__mdt>([SELECT Id, CatchAll__c, PriceBookId__c, CountryList__c FROM CV_Pricebook_Mapping__mdt]);

        for (CV_Pricebook_Mapping__mdt pricebookMapping : pricebookMappings) {
            configuredPricebooks.add(pricebookMapping.PriceBookId__c);
        }

        for (Pricebook2 pricebook2 : [SELECT Id, Name FROM Pricebook2 WHERE Name in :configuredPricebooks]) {
            pricebookIdsByNames.put(pricebook2.Name, pricebook2.Id);
        }

        for (CV_Pricebook_Mapping__mdt pricebookMapping : pricebookMappings) {
            if (pricebookMapping.CountryList__c != null) {
                for (String country : pricebookMapping.CountryList__c.split(',')) {
                    pricebookIdsByCountries.put(country.toUpperCase(), pricebookIdsByNames.get(pricebookMapping.PriceBookId__c));

                }
            } else if (pricebookMapping.CatchAll__c) {
                defaultPricebook = pricebookIdsByNames.get(pricebookMapping.PriceBookId__c);
            }
        }

        System.debug('============================== CV_OrderCreationService loadPriceBookMapping pricebookIdsByCountries: ' + pricebookIdsByCountries);
        System.debug('============================== CV_OrderCreationService loadPriceBookMapping defaultPriceBook: ' + defaultPriceBook);
    }

    private void loadPriceBookEntries() {

//        String priceBook = System.Label.CV_Default_Pricebook != null ? System.Label.CV_Default_Pricebook : 'CerbaVet';

        if (pricebookPricesByCurrencyByProductCodesByPricebookIds == null) {
            pricebookPricesByCurrencyByProductCodesByPricebookIds = new Map<String, Map<String, Map<String, Decimal>>>();
//            priceBookEntryIdsByCurrencyByProductCodes = new Map<String, Map<String, Id>>();
            priceBookEntryIdsByCurrencyByProductCodesByPricebookIds = new Map<String, Map<String, Map<String, Id>>>();

//            for (PricebookEntry pricebookEntry : [SELECT Id, Product2.ProductCode, ProductCode, UnitPrice, Pricebook2Id, CurrencyIsoCode FROM PricebookEntry WHERE Pricebook2.Name = :priceBook]) {
            for (PricebookEntry pricebookEntry : [
                    SELECT Id, Product2.ProductCode, ProductCode, UnitPrice, Pricebook2Id, CurrencyIsoCode
                    FROM PricebookEntry
                    WHERE Pricebook2.Name in :configuredPricebooks
                    ORDER BY Pricebook2Id
            ]) {
                String productCode = pricebookEntry.Product2.ProductCode;

                if (!pricebookPricesByCurrencyByProductCodesByPricebookIds.containsKey(pricebookEntry.Pricebook2Id)) {
                    pricebookPricesByCurrencyByProductCodesByPricebookIds.put(pricebookEntry.Pricebook2Id, new Map<String, Map<String, Decimal>>());
                }
                Map<String, Map<String, Decimal>> pricebookPricesByCurrencyByProductCodes = pricebookPricesByCurrencyByProductCodesByPricebookIds.get(pricebookEntry.Pricebook2Id);

                if (!pricebookPricesByCurrencyByProductCodes.containsKey(productCode)) {
                    pricebookPricesByCurrencyByProductCodes.put(productCode, new Map<String, Decimal>());
                }

                if (!priceBookEntryIdsByCurrencyByProductCodesByPricebookIds.containsKey(pricebookEntry.Pricebook2Id)) {
                    priceBookEntryIdsByCurrencyByProductCodesByPricebookIds.put(pricebookEntry.Pricebook2Id, new Map<String, Map<String, Id>>());
                }
                Map<String, Map<String, Id>> priceBookEntryIdsByCurrencyByProductCodes = priceBookEntryIdsByCurrencyByProductCodesByPricebookIds.get(pricebookEntry.Pricebook2Id);

                if (!priceBookEntryIdsByCurrencyByProductCodes.containsKey(productCode)) {
                    priceBookEntryIdsByCurrencyByProductCodes.put(productCode, new Map<String, Id>());
                }
                Map<String, Decimal> pricesByCurrency = pricebookPricesByCurrencyByProductCodes.get(productCode);
                Map<String, Id> pricebookIdsByCurrency = priceBookEntryIdsByCurrencyByProductCodes.get(productCode);

                pricesByCurrency.put(pricebookEntry.CurrencyIsoCode, pricebookEntry.UnitPrice);
                pricebookIdsByCurrency.put(pricebookEntry.CurrencyIsoCode,pricebookEntry.Id);

//                pricebookPricesByProductCodes.put(pricebookEntry.Product2.ProductCode, pricebookEntry.UnitPrice);
//                priceBookEntryIdsByProductCodes.put(pricebookEntry.ProductCode, pricebookEntry.Id);

//                if (pricebookId == null) {pricebookId = pricebookEntry.Pricebook2Id;  }
            }
        }
        System.debug('============================== CV_OrderCreationService loadPriceBookEntries pricebookPricesByCurrencyByProductCodesByPricebookIds # : ' + pricebookPricesByCurrencyByProductCodesByPricebookIds);

    }

    private void getAccountsParentN2(Account account, Map<Id, Id> accountN2IdsBySGLIds, Account sglAccount) {

        System.debug('=============== CV_OrderCreationService getAccountsParentN2 account Id : ' + account.Id);

        if (account.Est_Niveau_N2__c) {
            accountN2IdsBySGLIds.put(sglAccount.Id, account.Id);

        } else if (account.Parent != null) {
            getAccountsParentN2(account.Parent, accountN2IdsBySGLIds, sglAccount);
        }
    }


    private Map<String, Account> getAccountsByHexalisCodes(Set<String> accountHexalisCodes) {

        Map<String, Account> accountsByHexalisCodes = new Map<String, Account>();

        for (Account account : [
                SELECT Id, Code_SGL_etablissement__c, Conditions_de_Reglement_Cerbavet__c, CV_Global_discount__c, Est_Niveau_N2__c, BillingCountry, Depose_Labo__c,
                        ParentId, Parent.Est_Niveau_N2__c, AccountNumber, CurrencyIsoCode, Remise_sur_facture_Cerba_Vet__c, Parent.BillingCountry,
                        Parent.ParentId, Parent.Parent.Est_Niveau_N2__c, Parent.Parent.ParentId, Parent.Parent.Parent.Est_Niveau_N2__c, Parent.Parent.BillingCountry, Parent.Parent.Parent.BillingCountry,
                        Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Est_Niveau_N2__c, Parent.Parent.Parent.Parent.BillingCountry,
                        Parent.Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Parent.Est_Niveau_N2__c, Parent.Parent.Parent.Parent.Parent.BillingCountry, Exoneration_Frais_de_Gestion__c
                FROM Account
                WHERE AccountNumber in :accountHexalisCodes
        ]) {
            accountsByHexalisCodes.put(account.AccountNumber, account);
        }

        System.debug('============================== CV_OrderCreationService getAccountsByHexalisCodes accountsByHexalisCodes: ' + accountsByHexalisCodes);
        return accountsByHexalisCodes;
    }

    public String getPricebookId(String country) {

        if (country != null && pricebookIdsByCountries.containsKey(country.toUpperCase())) {
            return pricebookIdsByCountries.get(country.toUpperCase());
        } else {
            return defaultPricebook;
        }
    }


    public Map<String, Map<String, PricingInfo>> getPricesPerProductCodesPerDossierIds(Map<String, InformationDossier> informationDossiersByDossierIds) {

        //Expected to receive the information of automatic paiement from the account Map

        Map<String, Map<String, PricingInfo>> pricesPerProductCodesPerDossierIds = new Map<String, Map<String, PricingInfo>>();
        Map<String, Map<String, Decimal>> contractedPricesByProductCodesByAccountIds = new Map<String, Map<String, Decimal>>();

        Set<Id> accountIds = new Set<Id>();

        for (InformationDossier informationDossier : informationDossiersByDossierIds.values()) {
            if (informationDossier.accountInfo != null) {
                accountIds.add(informationDossier.accountInfo.Id);

            }
        }

        for (SBQQ__ContractedPrice__c contractedPrice : [
                SELECT Id, SBQQ__Account__c, SBQQ__Price__c, SBQQ__Product__r.ProductCode
                FROM SBQQ__ContractedPrice__c
                WHERE SBQQ__Account__c IN :accountIds
                ORDER BY SBQQ__Account__c
        ]) {
            if (!contractedPricesByProductCodesByAccountIds.containsKey(contractedPrice.SBQQ__Account__c)) {
                contractedPricesByProductCodesByAccountIds.put(contractedPrice.SBQQ__Account__c, new Map<String, Decimal>());
            }

            Map<String, Decimal> contractedPricesByProductCodes = contractedPricesByProductCodesByAccountIds.get(contractedPrice.SBQQ__Account__c);
            contractedPricesByProductCodes.put(contractedPrice.SBQQ__Product__r.ProductCode, contractedPrice.SBQQ__Price__c);
        }

        System.debug('================================ CV_OrderCreationServicee contractedPricesByProductCodesByAccountIds: ' + contractedPricesByProductCodesByAccountIds);

        for (String dossierId : informationDossiersByDossierIds.keySet()) {
            System.debug('============================== CV_OrderCreationService getPricesPerProductCodesPerDossierIds dossierId: ' + dossierId);

            Map<String, PricingInfo> pricesByExamCodes = new Map<String, PricingInfo>();

            Decimal globalDiscountPercentage = 0;
            InformationDossier informationDossier = informationDossiersByDossierIds.get(dossierId);

            Account account = informationDossier.accountInfo;
            System.debug('============================== CV_OrderCreationService getPricesPerProductCodesPerDossierIds account: ' + account);
            System.debug('============================== CV_OrderCreationService getPricesPerProductCodesPerDossierIds informationDossier: ' + informationDossier);

            Map<String, Decimal> contractedPrices = new Map<String, Decimal>();

            if (account != null) {
                if (contractedPricesByProductCodesByAccountIds.containsKey(account.Id)) { contractedPrices = contractedPricesByProductCodesByAccountIds.get(account.Id);  }
                if (account.Remise_sur_facture_Cerba_Vet__c != null) { globalDiscountPercentage += account.Remise_sur_facture_Cerba_Vet__c; }
            }

            if (informationDossier.specialDiscountPerc != null && informationDossier.specialDiscountPerc != 0) {
                globalDiscountPercentage = informationDossier.specialDiscountPerc;
            }
//            globalDiscountPercentage += informationDossier.specialDiscountPerc;

            System.debug('============================== CV_OrderCreationService getPricesPerProductCodesPerDossierIds globalDiscountPercentage: ' + globalDiscountPercentage);

            Integer countDegressifPrice = 0;

            String currentCurrency = account != null ? account.CurrencyIsoCode : 'EUR';
            String pricebookId = informationDossier.pricebookId;
            Map<String, Map<String, Decimal>> pricebookPricesByCurrencyByProductCodes = pricebookPricesByCurrencyByProductCodesByPricebookIds.containsKey(pricebookId) ? pricebookPricesByCurrencyByProductCodesByPricebookIds.get(pricebookId) : new Map<String, Map<String, Decimal>>();
            Map<String, Map<String, Id>> priceBookEntryIdsByCurrencyByProductCodes = priceBookEntryIdsByCurrencyByProductCodesByPricebookIds.containsKey(pricebookId) ? priceBookEntryIdsByCurrencyByProductCodesByPricebookIds.get(pricebookId) : new Map<String, Map<String, Id>>();

            System.debug('============================== CV_OrderCreationService getPricesPerProductCodesPerDossierIds priceBookEntryIdsByCurrencyByProductCodes: ' + priceBookEntryIdsByCurrencyByProductCodes);
            System.debug('============================== CV_OrderCreationService getPricesPerProductCodesPerDossierIds pricebookPricesByCurrencyByProductCodes: ' + pricebookPricesByCurrencyByProductCodes);

            for (String examCode : informationDossier.examCodes) {

                PricingInfo pricingInfo = new PricingInfo();
                pricingInfo.productId = productIdsByHexalisCodes.get(examCode);

//                Decimal basePrice = contractedPrices.containsKey(examCode) ? contractedPrices.get(examCode) :
//                        (priceBookEntryIdsByCurrencyByProductCodes.containsKey(examCode) ? pricebookPricesByCurrencyByProductCodes.get(examCode).get(currentCurrency) : 0);

                Decimal basePrice;


                if (contractedPrices.containsKey(examCode)) {
                    basePrice = contractedPrices.get(examCode);

                } else if (priceBookEntryIdsByCurrencyByProductCodes.containsKey(examCode) && pricebookPricesByCurrencyByProductCodes.get(examCode).containsKey(currentCurrency)) {
                    basePrice = pricebookPricesByCurrencyByProductCodes.get(examCode).get(currentCurrency);

                } else {
                    basePrice = 0;
                }

                System.debug('================================> Base Price ' + examCode + ' : ' + basePrice);

                pricingInfo.basePrice = pricebookPricesByCurrencyByProductCodes.containsKey(examCode) && pricebookPricesByCurrencyByProductCodes.get(examCode).containsKey(currentCurrency) ? pricebookPricesByCurrencyByProductCodes.get(examCode).get(currentCurrency) : 0;

                if (!contractedPrices.containsKey(examCode) && !pricebookPricesByCurrencyByProductCodes.containsKey(examCode) && !informationDossier.isAtel) {
                    informationDossier.isAtel = true;
                    informationDossier.atelReason = 'Prix à 0 car pas de contracted price ni d\'entrée dans le pricebook: ' + examCode;

                } else {

                    if (decreasingPriceProductCodes.contains(examCode)) {
                        countDegressifPrice++;
                        System.debug('================================> countDegressifPrice: ' + countDegressifPrice);
                        System.debug('================================> degressive discount: ' + degressiveDiscountByNumberOfProducts.get(countDegressifPrice));

                        basePrice = basePrice - degressiveDiscountByNumberOfProducts.get(countDegressifPrice);
                    }

                    if (!nonDiscountableProductCodes.contains(examCode)) {
//                        basePrice = globalDiscountPercentage != 0 ? basePrice - (basePrice * (globalDiscountPercentage / 10000)): basePrice ;
                        basePrice = globalDiscountPercentage != 0 ? basePrice - (basePrice * (globalDiscountPercentage / 100)): basePrice ;
                    }
                }

                basePrice = basePrice < 0 ? 0 : basePrice;

                pricingInfo.unitPrice = basePrice.setScale(2);
                pricingInfo.discount = pricingInfo.basePrice - pricingInfo.unitPrice;

                System.debug('================================> Discounted Price ' + examCode + ' : ' + basePrice);

                pricesByExamCodes.put(examCode, pricingInfo);

            }
            pricesPerProductCodesPerDossierIds.put(dossierId, pricesByExamCodes);
        }

        System.debug('============================== CV_OrderCreationService getPricesPerProductCodesPerDossierIds pricesPerProductCodesPerDossierIds: ' + pricesPerProductCodesPerDossierIds);

        return pricesPerProductCodesPerDossierIds;

    }

    public class InformationDossier {

        public String dossierId { get; set; }
        public List<String> examCodes { get; set; }
        public Boolean isAtel { get; set; }
        public String atelReason { get; set; }
        public Decimal specialDiscountPerc { get; set; }
        public Account accountInfo { get; set; }
        public Tech_Hexalis_Order_Import__c mainTechInfo { get; set; }
        public Id billingAccountId { get; set; }
        public String pricebookId { get; set; }

        public InformationDossier(String dossierId, List<String> examCodes, Boolean isAtel, String atelReason, Decimal extraPercentage, Account account, Tech_Hexalis_Order_Import__c mainTechInfo, Id billingAccountId, String pricebookId) {

            this.dossierId = dossierId;
            this.examCodes = examCodes;
            this.isAtel = isAtel;
            this.atelReason = atelReason;
            this.specialDiscountPerc = extraPercentage;
            this.accountInfo = account;
            this.mainTechInfo = mainTechInfo;
            this.billingAccountId = billingAccountId;
            this.pricebookId = pricebookId;

        }
    }

    public class PricingInfo {
        public Decimal basePrice { get; set; }
        public Decimal unitPrice { get; set; }
        public Decimal discount { get; set; }
        public Id productId { get; set; }
    }

    public class TransportInfo {
        public String firstTechDossier { get; set; }
        public Integer nbrDossier { get; set; }

        public TransportInfo(String dossierId) {
            nbrDossier = 1;
            this.firstTechDossier = dossierId;
        }
    }
}