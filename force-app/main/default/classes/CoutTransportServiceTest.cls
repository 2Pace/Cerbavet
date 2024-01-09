@isTest
private class CoutTransportServiceTest {

    @isTest
    static void updateFromDemandeTest(){
        Cout_de_transport__c coutTransportMensuel = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Validé par la direction commerciale');
        coutTransportMensuel = [Select Id, Name/*, Mode_de_calcul_du_cout__c, Cout_journalier_semaine_TTC__c, Cout_journalier_samedi_TTC__c, Montant_forfait_mensuel_TTC__c*/, 
                         Cout_mensuel_attendu_TTC__c/*, Cout_moyen_mensuel__c*/, Date_de_demarrage__c, Date_de_fin__c 
                        From Cout_de_transport__c
                        Where Id = :coutTransportMensuel.Id];
        List<Mensualite__c> mensualites = MensualiteService.generateMensualites(coutTransportMensuel);
        insert mensualites;
        Demande__c demande = DataFactoryTest.createDemande(coutTransportMensuel.Id, 'Demande de modification d\'une facture');
        List<Demande__c> demandes = new List<Demande__c>();
        demandes.add(demande);
        Map<Id, Cout_de_transport__c> cdtsById = new Map<Id, Cout_de_transport__c>();
        cdtsById.put(coutTransportMensuel.Id, coutTransportMensuel);
        
        test.startTest();
        CoutTransportService.updateFromDemande(demandes, cdtsById);
        test.stopTest();
        
        coutTransportMensuel = [Select Id, Name/*, Mode_de_calcul_du_cout__c, Cout_journalier_semaine_TTC__c, Cout_journalier_samedi_TTC__c, Montant_forfait_mensuel_TTC__c*/, 
                         Cout_mensuel_attendu_TTC__c/*, Cout_moyen_mensuel__c*/, Date_de_demarrage__c, Date_de_fin__c 
                        From Cout_de_transport__c
                        Where Id = :coutTransportMensuel.Id];
        System.assert(coutTransportMensuel.Cout_mensuel_attendu_TTC__c == demande.Montant_forfait_mensuel_TTC__c);
    }
    
}