@isTest
private class DemandeTriggerTest {

    @isTest
    static void demandeTriggerTest(){
        Cout_de_transport__c coutTransport = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Validé par la direction commerciale');
        coutTransport = [Select Id, Name,Cout_mensuel_attendu_TTC__c, Date_de_demarrage__c, Date_de_fin__c 
                        From Cout_de_transport__c
                        Where Id = :coutTransport.Id];
        List<Mensualite__c> mensualites = MensualiteService.generateMensualites(coutTransport);
        insert mensualites;
        Decimal montantOrigin = mensualites.get(0).Montant_provisionne_TTC__c;
        Demande__c demande1 = DataFactoryTest.createDemande(coutTransport.Id, 'Demande de modification d\'une facture');
        Demande__c demande2 = DataFactoryTest.createDemande(coutTransport.Id, 'Demande de suppression d\'une facture');
        
        test.startTest();
        
        demande1.Statut__c = 'Validée par la direction commerciale';
        update demande1;
        mensualites = [Select Montant_provisionne_TTC__c From Mensualite__c];
        coutTransport = [Select Id, Name, Cout_mensuel_attendu_TTC__c, Date_de_demarrage__c, Date_de_fin__c
                        From Cout_de_transport__c
                        Where Id = :coutTransport.Id];
        System.assert(mensualites.size() == (coutTransport.Date_de_demarrage__c.monthsBetween(coutTransport.Date_de_fin__c) + 1) 
                      && mensualites.get(0).Montant_provisionne_TTC__c == coutTransport.Cout_mensuel_attendu_TTC__c
                      && montantOrigin != mensualites.get(0).Montant_provisionne_TTC__c);
        
        demande2.Statut__c = 'Validée par la direction commerciale';
        update demande2;
        mensualites = [Select Montant_provisionne_TTC__c From Mensualite__c];
        System.assert(mensualites.size() == 0);
        
        test.stopTest();
    }
    
}