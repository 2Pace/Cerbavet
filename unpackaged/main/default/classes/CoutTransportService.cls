public inherited sharing class CoutTransportService {

    public static String FORFAIT_JOUR = 'Forfait Journalier';
    public static String JOUR_CIRCULATION_STD = 'LMMJV';
    public static String JOUR_CIRCULATION_SAMEDI = 'S';
    public static String STATUT_VALIDE = 'Validé par la direction commerciale';
    public static String STATUT_BROUILLON = 'Brouillon';

    
    /**
     * Met a jour le cout de transport suite a une demande de modification.
     */
    public static void updateFromDemande(List<Demande__c> demandes, Map<Id, Cout_de_transport__c> cdtsById){
        system.debug('CoutTransportService.updateFromDemande');
        List<Cout_de_transport__c> cdtsToUpdate = new List<Cout_de_transport__c>();
        for(Demande__c demande : demandes){
            if(demande.RecordTypeId == Schema.SObjectType.Demande__c.getRecordTypeInfosByName()
                                        .get('Demande de modification d\'une facture').getRecordTypeId()){
                Cout_de_transport__c cdt = cdtsById.get(demande.Facture_directe__c);
                //cdt.Montant_forfait_mensuel_TTC__c = demande.Montant_forfait_mensuel_TTC__c;
                cdt.Cout_mensuel_attendu_TTC__c = demande.Montant_forfait_mensuel_TTC__c;
                //cdt.Cout_journalier_semaine_TTC__c = demande.Montant_du_cout_journalier_semaine_TTC__c;
                //cdt.Cout_journalier_samedi_TTC__c = demande.Montant_du_cout_journalier_samedi_TTC__c;
                cdtsToUpdate.add(cdt);
            }
        }
        if(cdtsToUpdate.size() > 0){
            update cdtsToUpdate;
        }
    }
    
    /*
     * Verifie si les couts de transports n'ont pas déjà des mensualités et retourne la liste à générer.
     */
    public static List<Cout_de_transport__c> checkCoutForGeneration(List<Cout_de_transport__c> coutToCheck){
        List<Id> cdtsId = new List<Id>();
        for(Cout_de_transport__c coutTransport : coutToCheck){
            cdtsId.add(coutTransport.Id);
        }
        
        // Verifie si les mensualités n'ont pas été générées pour les couts récupérés
        List<Mensualite__c> mensualites = MensualiteDAO.getCurrentMensualite(cdtsId);
        Map<Id, Mensualite__c> mensualiteByCDT = new Map<Id, Mensualite__c>();
        for(Mensualite__c mensualite : mensualites){
            mensualiteByCDT.put(mensualite.Cout_de_transport__c, mensualite);
        }
        
        // Ajoute les couts correspondants...
        List<Cout_de_transport__c> coutTransportList = new List<Cout_de_transport__c>();
        for(Cout_de_transport__c coutTransport : coutToCheck){
            if(mensualiteByCDT.get(coutTransport.Id) == null){
                coutTransportList.add(coutTransport);
            }
        }
        
        return coutTransportList;
    }
    
    public static Map<Id, Cout_de_transport__c> getMapCoutsByIds(List<Id> cdtsId){
        Map<Id, Cout_de_transport__c> mapCouts = new Map<Id, Cout_de_transport__c>();
        for(Cout_de_transport__c cdt : CoutTransportDao.getCoutsByIds(cdtsId)){
            mapCouts.put(cdt.Id, cdt);
        }
        
        return mapCouts;
    }
    
}