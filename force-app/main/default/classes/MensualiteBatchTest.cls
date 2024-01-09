@isTest
private class MensualiteBatchTest {

    @isTest
    static void mensualiteBatchTest(){
        Cout_de_transport__c coutTransportMensuel = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Validé par la direction commerciale');
        
        test.startTest();
        GenerateMensualitesController.generateAllMensualites();
        test.stopTest();
        
        List<Mensualite__c> mensualites = [Select Montant_provisionne_TTC__c From Mensualite__c];
        System.assert(mensualites.size() == (coutTransportMensuel.Date_de_demarrage__c.monthsBetween(coutTransportMensuel.Date_de_fin__c) + 1) 
                      && mensualites.get(0).Montant_provisionne_TTC__c == coutTransportMensuel.Cout_mensuel_attendu_TTC__c);
    }
    
}