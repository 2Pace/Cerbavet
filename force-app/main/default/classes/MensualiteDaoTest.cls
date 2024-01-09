@isTest
private class MensualiteDaoTest {
    
    @isTest
    static void mensualiteDaoTest(){
        Cout_de_transport__c coutTransportMensuel = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Brouillon');
        coutTransportMensuel = [Select Id, Name/*, Mode_de_calcul_du_cout__c, Cout_journalier_semaine_TTC__c, Cout_journalier_samedi_TTC__c, Montant_forfait_mensuel_TTC__c*/, 
                             Cout_mensuel_attendu_TTC__c/*, Cout_moyen_mensuel__c*/, Date_de_demarrage__c, Date_de_fin__c 
                            From Cout_de_transport__c
                            Where Id = :coutTransportMensuel.Id];
        List<Mensualite__c> mensualites = MensualiteService.generateMensualites(coutTransportMensuel);
        insert mensualites;
        List<Id> cdtsId = new List<Id>();
        cdtsId.add(coutTransportMensuel.Id);
        
        test.startTest();
        List<Mensualite__c> res1 = MensualiteDao.getCurrentMensualite(cdtsId);
        List<Mensualite__c> res2 = MensualiteDao.getMensualitesFromCoutAndDate(coutTransportMensuel.Id, system.today());
        test.stopTest();
        
        system.assert(res1.size() >= 1 && res2.size() == mensualites.size());
    }

}