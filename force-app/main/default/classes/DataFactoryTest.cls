public class DataFactoryTest {
    
    public static Account createCompte(String accountName){
        Account compte = new Account(Name = accountName);
        compte.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Etablissement').getRecordTypeId();
        compte.ShippingStreet = 'Rue de Paris';
        compte.ShippingCity = 'Paris';
        compte.ShippingPostalCode = '93100';
        compte.ShippingCountry = 'France';

        insert compte;
        return compte;
    }
    
    public static Account createCompte(String accountName,String recordType){
        Account compte = new Account(Name = accountName);
        compte.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();
        compte.ShippingStreet = 'Rue de Paris';
        compte.ShippingCity = 'Paris';
        compte.ShippingPostalCode = '93100';
        compte.ShippingCountry = 'France';

        insert compte;
        return compte;
    }

    public static Contrats_Conventions__c createContrat(String contractName){
        Contrats_Conventions__c contrat = new Contrats_Conventions__c(Name = contractName);
        //contrat.Nomduclient__c = createCompte('test').Id;
        contrat.Date_de_debut__c = system.today();
        contrat.Date_de_fin__c = system.today().addYears(1);
        contrat.Type_de_contrat__c = 'Contrat d’établissement';
        
        insert contrat;
        return contrat;
    }
    
    public static Prestation_de_transport__c createPrestation(String prestaName){
        Prestation_de_transport__c prestation = new Prestation_de_transport__c(/*Name = prestaName*/);
        prestation.Client__c = createCompte('client').Id;
        prestation.Fournisseur__c = createCompte('fournisseur','Fournisseur').Id;
        prestation.Statut__c = 'Active';
        prestation.Date_de_mise_en_place__c = system.today();
        prestation.Date_de_suppression__c = system.today().addYears(1);
        prestation.Date_de_reponse_souhaitee__c = system.today().addMonths(1);
        prestation.Biologistic_customer_group__c = 'Cerba';
        System.debug('pre' + prestation);
        
        insert prestation;
        return prestation;
    }
    
    public static Cout_de_transport__c createCoutTransport(String modeCalcul, String statut){
        Cout_de_transport__c coutTransport = new Cout_de_transport__c();
        coutTransport.Client__c = createCompte('Test').Id;
        coutTransport.Contrat__c = createContrat('test').Id;      
        coutTransport.Cout_mensuel_attendu_TTC__c = 1500;
        coutTransport.Date_de_demarrage__c = system.today();
        coutTransport.Date_de_fin__c = system.today().addYears(1);       
        coutTransport.Statut__c = statut; // Brouillon ou Validé/Refusé par la direction commerciale
        coutTransport.TVA_applicable__c = 'Oui';
        Schema.RecordTypeInfo recType = Schema.SObjectType.Cout_de_transport__c.getRecordTypeInfosByDeveloperName().get('Facture_directe_Laboratoire_Transporteur') == null 
            ? Schema.SObjectType.Cout_de_transport__c.getRecordTypeInfosByDeveloperName().get('Facture_directe_Laboratoire_ou_Transporteur') 
            : Schema.SObjectType.Cout_de_transport__c.getRecordTypeInfosByDeveloperName().get('Facture_directe_Laboratoire_Transporteur');
        coutTransport.RecordTypeId = recType.getRecordTypeId();
        coutTransport.Type_de_cout__c = 'L';
        coutTransport.Type_d_emetteur__c = 'Laboratoire';

            
        insert coutTransport;
        return coutTransport;
    }
            
    public static Demande__c createDemande(Id factureDirecteId, String RecordType){
        Demande__c demande = new Demande__c();
        demande.Facture_directe__c = factureDirecteId;
        demande.RecordTypeId = Schema.SObjectType.Demande__c.getRecordTypeInfosByName().get(RecordType).getRecordTypeId();
        demande.Client__c = createCompte('toto').Id;
        demande.Prestation_de_transport__c = createPrestation('toto').Id;
        demande.Statut__c = 'Nouvelle';
        demande.Debut_d_application_de_la_modification__c = system.today();
        demande.Date_de_fin__c = system.today();
        demande.Montant_forfait_mensuel_TTC__c = 150;
        insert demande;
        return demande;
    }
    
}