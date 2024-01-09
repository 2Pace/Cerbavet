@isTest
private class MensualiteServiceTest {

    
    @isTest
    static void getStartDateTest(){
        // I HAVE
        Date todayDate = Date.newInstance(2020, 1, 2);
        Date dateDemarrage1 = Date.newInstance(2019, 3, 2);
        Date dateDemarrage2 = Date.newInstance(2020, 3, 2);
        
        // I DO
        Date startDate1 = MensualiteService.getStartDate(dateDemarrage1,todayDate);
        Date startDate2 = MensualiteService.getStartDate(dateDemarrage2,todayDate);

        
        // I TEST
        System.assertEquals(todayDate.toStartOfMonth(), startDate1);
        System.assertEquals(dateDemarrage2, startDate2);
                
         // I HAVE
        Date todayDate2 = Date.newInstance(2020, 6, 2);
        Date dateDemarrage3 = Date.newInstance(2020, 8, 2);
        
        // I DO
        Date startDate3 = MensualiteService.getStartDate(dateDemarrage3,todayDate2);
        
        // I TEST
        System.assertEquals(dateDemarrage3, startDate3);
        
    }
    
    
    @isTest
    static void generateMensualitesTest(){
        Cout_de_transport__c coutTransportMensuel = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Brouillon');
        coutTransportMensuel = [Select Id, Name/*, Mode_de_calcul_du_cout__c, Cout_journalier_semaine_TTC__c, Cout_journalier_samedi_TTC__c, Montant_forfait_mensuel_TTC__c*/, 
                         Cout_mensuel_attendu_TTC__c/*, Cout_moyen_mensuel__c*/, Date_de_demarrage__c, Date_de_fin__c 
                        From Cout_de_transport__c
                        Where Id = :coutTransportMensuel.Id];
             
        test.startTest();
        List<Mensualite__c> mensualites1 = MensualiteService.generateMensualites(coutTransportMensuel);

        test.stopTest();
        
        System.assert(mensualites1.size() == (coutTransportMensuel.Date_de_demarrage__c.monthsBetween(coutTransportMensuel.Date_de_fin__c) + 1) 
                      && mensualites1.get(0).Montant_provisionne_TTC__c == coutTransportMensuel.Cout_mensuel_attendu_TTC__c);

    }
    
      @isTest
    static void generateMensualitesTriggerTest(){
        Cout_de_transport__c coutTransportMensuel = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Brouillon');
        coutTransportMensuel = [Select Id, Name, Cout_mensuel_attendu_TTC__c, Date_de_demarrage__c, Date_de_fin__c 
                        From Cout_de_transport__c
                        Where Id = :coutTransportMensuel.Id];

        test.startTest();
        List<Mensualite__c> mensualites1 = MensualiteService.generateMensualitesTrigger(coutTransportMensuel);

        test.stopTest();
        
        System.assert(mensualites1.size() == (coutTransportMensuel.Date_de_demarrage__c.monthsBetween(coutTransportMensuel.Date_de_fin__c) + 1) 
                      && mensualites1.get(0).Montant_provisionne_TTC__c == coutTransportMensuel.Cout_mensuel_attendu_TTC__c);

    }
    
    @isTest
    static void updateOrDeleteFromDemandeTest(){
        Cout_de_transport__c coutTransportMensuel = DataFactoryTest.createCoutTransport('Forfait mensuel', 'Validé par la direction commerciale');
        coutTransportMensuel = [Select Id, Name/*, Mode_de_calcul_du_cout__c, Cout_journalier_semaine_TTC__c, Cout_journalier_samedi_TTC__c, Montant_forfait_mensuel_TTC__c*/, 
                         Cout_mensuel_attendu_TTC__c/*, Cout_moyen_mensuel__c*/, Date_de_demarrage__c, Date_de_fin__c 
                        From Cout_de_transport__c
                        Where Id = :coutTransportMensuel.Id];
        List<Mensualite__c> mensualites = MensualiteService.generateMensualites(coutTransportMensuel);
        insert mensualites;
        Demande__c demande = DataFactoryTest.createDemande(coutTransportMensuel.Id, 'Demande de suppression d\'une facture');
        List<Demande__c> demandes = new List<Demande__c>();
        demandes.add(demande);
        Map<Id, Cout_de_transport__c> cdtsById = new Map<Id, Cout_de_transport__c>();
        cdtsById.put(coutTransportMensuel.Id, coutTransportMensuel);
        
        test.startTest();
        MensualiteService.updateOrDeleteFromDemande(demandes, cdtsById);
        test.stopTest();
        
        mensualites = [Select Montant_provisionne_TTC__c From Mensualite__c];
        System.assert(mensualites.size() == 0);
    }
    
}