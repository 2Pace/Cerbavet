@isTest
private class CoutTransportTriggerTest {
    
    @isTest
    static void coutTransportTriggerTest(){
        Cout_de_transport__c coutTransport = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Brouillon');
        
        test.startTest();
        coutTransport.Statut__c = 'Validé par la direction commerciale';
        update coutTransport;
        test.stopTest();
        
        List<Mensualite__c> mensualites = [Select Montant_provisionne_TTC__c From Mensualite__c];
        System.assert(mensualites.size() == (coutTransport.Date_de_demarrage__c.monthsBetween(coutTransport.Date_de_fin__c) + 1) 
                      && mensualites.get(0).Montant_provisionne_TTC__c == coutTransport.Cout_mensuel_attendu_TTC__c);
    }
    
}