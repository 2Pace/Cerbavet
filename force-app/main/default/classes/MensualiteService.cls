public inherited sharing class MensualiteService {
    
    /**
     * Permet de générer les mensualités d'un cout de transport pour l'année en cours.
     */
    public static List<Mensualite__c> generateMensualites(Cout_de_transport__c coutTransport){

        List<Mensualite__c> mensualites = new List<Mensualite__c>();
        
        // Génération des mensualités pour l'année du début du contrat ou l'année en cours.
        Date startDate = (coutTransport.Date_de_demarrage__c != null && coutTransport.Date_de_demarrage__c.year() == system.today().year()) 
            ? coutTransport.Date_de_demarrage__c : Date.newInstance(system.today().year(),1,1);
        
        List<Date> mensualitesDate = getMonthsUntilEndOfYearOrContract(startDate, coutTransport.Date_de_fin__c);
        for(Date mensualiteDate : mensualitesDate){
            Mensualite__c mensualite = new Mensualite__c();
            mensualite.Cout_de_transport__c = coutTransport.Id;
            mensualite.Date_de_la_mensualite__c = mensualiteDate;
            mensualite.Montant_provisionne_TTC__c = calculateProvision(coutTransport);
            mensualites.add(mensualite);
        }
        
        return mensualites;
    }
    
    /**
     * Permet de générer les mensualités d'un cout de transport pour l'année en cours.
     */
    public static List<Mensualite__c> generateMensualitesTrigger(Cout_de_transport__c coutTransport){
        List<Mensualite__c> mensualites = new List<Mensualite__c>();
        
        // Génération des mensualités pour l'année du début du contrat ou l'année en cours.
        Date startDate = coutTransport.Date_de_demarrage__c;
        if(coutTransport.Date_de_demarrage__c == null){
            startDate = Date.newInstance(system.today().year(), 1,1);
        }
             
        List<Date> mensualitesDate = getMonthsUntilEndOfYearOrContract(startDate, coutTransport.Date_de_fin__c);
        for(Date mensualiteDate : mensualitesDate){
            Mensualite__c mensualite = new Mensualite__c();
            mensualite.Cout_de_transport__c = coutTransport.Id;
            mensualite.Date_de_la_mensualite__c = mensualiteDate;
            mensualite.Montant_provisionne_TTC__c = calculateProvision(coutTransport);
            mensualites.add(mensualite);
        }
        
        return mensualites;
    }
    
    @TestVisible
    private static Date getStartDate(Date dateDemarrage,Date todayDate){
        return (dateDemarrage != null && dateDemarrage.year() < todayDate.year()) 
            ? todayDate.toStartOfMonth()  :dateDemarrage;
    }
    
    
    /**
     * Met a jour le montant des mensualité suite a une demande de modification ou supprime les mensualité suite a une demande de suppression.
     */
    public static void updateOrDeleteFromDemande(List<Demande__c> demandes, Map<Id, Cout_de_transport__c> cdtsById){

       	List<Mensualite__c> mensualiteToUpdate = new List<Mensualite__c>();
        List<Mensualite__c> mensualiteToDelete = new List<Mensualite__c>();
        
        for(Demande__c demande : demandes){
            Cout_de_transport__c coutTransport = cdtsById.get(demande.Facture_directe__c);
            if(demande.RecordTypeId == Schema.SObjectType.Demande__c.getRecordTypeInfosByName()
                                        .get('Demande de modification d\'une facture').getRecordTypeId()){
                List<Mensualite__c> mensualites = MensualiteDAO.getMensualitesFromCoutAndDate(coutTransport.Id, demande.Debut_d_application_de_la_modification__c);
                for(Mensualite__c mensualite : mensualites){
                    mensualite.Montant_provisionne_TTC__c = calculateProvision(coutTransport);
                }
                mensualiteToUpdate.addAll(mensualites);
            } else if(demande.RecordTypeId == Schema.SObjectType.Demande__c.getRecordTypeInfosByName()
                                        .get('Demande de suppression d\'une facture').getRecordTypeId()){
                List<Mensualite__c> mensualites = MensualiteDAO.getMensualitesFromCoutAndDate(coutTransport.Id, demande.Date_de_fin__c);
          
                mensualiteToDelete.addAll(mensualites);
            }
        }
        
        if(mensualiteToUpdate.size() > 0){
            update mensualiteToUpdate;
        }
        if(mensualiteToDelete.size() > 0){
            delete mensualiteToDelete;
        }
    }
    
    public static Decimal calculateProvision(Cout_de_transport__c coutTransport){
            return coutTransport.Cout_mensuel_attendu_TTC__c;     
    }
    
    // ######################################
    
    private static List<Date> getMonthsUntilEndOfYearOrContract(Date startOfCout, Date endOfCout){
        system.debug('MensualiteService.getMonthsUntilEndOfYearOrContract');
        List<Date> mensualitesDate = new List<Date>();
        mensualitesDate.add(startOfCout);
        
        Date startOfMonth = startOfCout.toStartOfMonth().addMonths(1);
        while(endOfCout == null ? startOfMonth.year() <= system.today().year() : startOfMonth < endOfCout){
            mensualitesDate.add(Date.newInstance(startOfMonth.year(), startOfMonth.month(), startOfMonth.day()));
            startOfMonth = startOfMonth.addMonths(1);
        }
        
        system.debug('mensualitesDate (' + mensualitesDate.size() + ') : ' + mensualitesDate);
        return mensualitesDate;
    }
  
}