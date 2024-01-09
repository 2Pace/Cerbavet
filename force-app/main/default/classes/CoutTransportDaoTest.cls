@isTest
private class CoutTransportDaoTest {

    @isTest
    static void coutTransportDaoTest(){
        Cout_de_transport__c coutTransportMensuel = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Validé par la direction commerciale');
        List<Id> coutsId = new List<Id>();
        coutsId.add(coutTransportMensuel.Id);
        
        test.startTest();
        List<Cout_de_transport__c> cds1 = CoutTransportDao.getAllCurrentCouts();
        List<Cout_de_transport__c> cds2 = CoutTransportDao.getCoutsByIds(coutsId);
        test.stopTest();
        
        system.assert(cds1.size() == 1 && cds2.size() == 1);
    }
    
}