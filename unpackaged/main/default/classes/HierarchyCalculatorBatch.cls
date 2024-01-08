/**
 * @description       : Batch calculant la hiérarchier AN1-2-3 des comptes SGL Bi-Spé
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 17-04-2022
 * @last modified by  : Michaël Cabaraux
**/

global class HierarchyCalculatorBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private static final String RECTYPE_SGL_BI_SPE = 'Compte_Client_SGL_BI';

    private Integer nbrParentNull = 0;
    private Integer nbrParentPopulated = 0;
    private Integer totalBiSpec = 0;
    private Integer nbrErrors = 0;

    private User currentUser;

    private String errorReport = '';
    private String executionReport = '';

    private Hierarchy_Batch_Param__mdt batchParams;

    public HierarchyCalculatorBatch() {

        batchParams = [SELECT Bypass_VR__c, Generate_Error_Report__c, Generate_Exec_Report__c FROM Hierarchy_Batch_Param__mdt WHERE DeveloperName = 'Default'];

    }


    /**
    * Démarrage du batch et sélection des comptes bi-spe à traiter
    * @param bc contexte d'exécution du batch
    * @return une itération de listes de comptes Bi-Spé (le nombre d'éléments dépend du batch size (par défaut 200)
    */
    global Iterable<sObject> start(Database.BatchableContext bc) {

        System.debug('=============== HierarchyCalculatorBatch buildHierarchyStructure Démarrage à  : ' + Datetime.now());

        if (batchParams.Bypass_VR__c) {

            currentUser =  new User(
                    Id = UserInfo.getUserId(),
                    Tech_By_Pass_VR__c = true
            );
            update currentUser;
        }


        // Sélectionner tous les comprtes SGL Bi Spé
        // Sélectionner le niveau de hiérarchie le plus haut possible en un seul SOQL ==> 5 Afin de limiter le nombre de SOQL
        String query = 'SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c, Name, Parent.Name, ';
        query += 'ParentId, Parent.Est_Niveau_N2__c, Parent.ParentId, Parent.Parent.Est_Niveau_N2__c, Parent.Parent.Name, ';
        query += 'Parent.Parent.ParentId, Parent.Parent.Parent.Est_Niveau_N2__c, Parent.Parent.Parent.Name, ';
        query += 'Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Est_Niveau_N2__c, Parent.Parent.Parent.Parent.Name, ';
        query += 'Parent.Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Parent.Est_Niveau_N2__c, Parent.Parent.Parent.Parent.Parent.Name ';
        query += 'FROM Account ';
        query += 'WHERE  RecordType.DeveloperName = :RECTYPE_SGL_BI_SPE ';
//        query += 'AND Id = \'0011t000017Cs2FAAS\'';
//        query += 'LIMIT 450' ; //TODO remove for DEV purpose
//        query += 'AND Id in (\'0011t000017CthEAAS\', \'0011t000017CvdXAAS\',\'0011t000017CwUaAAK\', \'0011t000017CvvrAAC\',\'0011t000017CuZFAA0\',\'0011t000017CqsyAAC\',\'0011t000017Cs2FAAS\')';

        return Database.getQueryLocator(query);

    }


    /**
    * Corps d'excécution du batch, traite une liste de comptes Bi-Spe
    * @param bc contexte d'exécution du batch
    * @param biSpeAccounts list de comptes Bi-Spe à traiter --> le nombre d'éléments dépend du batch size (par défaut 200)
    */
    global void execute(Database.BatchableContext bc, List<Account> biSpeAccounts) {

        System.debug('=============== HierarchyCalculatorBatch buildHierarchyStructure biSpeAccounts : ' + biSpeAccounts[0].Parent.Name);

        List<Account> accountsToUpdate = new List<Account>();
        Set<Account> accountsWithParents = new Set<Account>();
        Map<Id, Account> biSpeAccountsByIds = new Map<Id, Account>();

        for (Account biSpeAccount : biSpeAccounts) {
            biSpeAccountsByIds.put(biSpeAccount.Id, biSpeAccount);

//            System.debug('=============== HierarchyCalculatorBatch Compte Bi-Spe:  ' + biSpeAccount.Name + ' - ' + biSpeAccount.Id);
            if (biSpeAccount.ParentId == null) {

                // SGL n'a pas de parent
                biSpeAccount.Ascendant_N3__c = null;
                biSpeAccount.Ascendant_N2__c = null;
                biSpeAccount.Ascendant_N1__c = null;

                System.debug('=============== HierarchyCalculatorBatch Bi-Spe: ' + biSpeAccount.Name + ' - ' + biSpeAccount.Id);
                System.debug('=====================> HierarchyCalculatorBatch Parent == Null');
                System.debug('========================> Ascendant_N1__c: ' + biSpeAccount.Ascendant_N1__c);
                System.debug('========================> Ascendant_N2__c: ' + biSpeAccount.Ascendant_N2__c);
                System.debug('========================> Ascendant_N3__c: ' + biSpeAccount.Ascendant_N3__c);

                nbrParentNull++;
                totalBiSpec++;
                executionReport = HierarchyCalculatorBatchService.addLineToReport(biSpeAccount, null, executionReport, false, null);

                accountsToUpdate.add(biSpeAccount);

            } else {

                //SGL marqué pour calcul de hiérarchie --> a au moins un parent
                accountsWithParents.add(biSpeAccount);

            }
        }

        if (!accountsWithParents.isEmpty()) {

            // Construction de la hierarchie par compte SGL ==> chaque compte SGL sera associé à une liste de noeud représant sa hierarchie de comptes
            Map<Id, List<HierarchyCalculatorBatchService.Node>> hierarchyStructure = HierarchyCalculatorBatchService.buildHierarchyStructure(accountsWithParents);

            for (Id accountId : hierarchyStructure.keySet()) {
                Integer topLevelEstN2Index = -1;

                Account biSpeAccount = biSpeAccountsByIds.get(accountId);
                System.debug('=============== HierarchyCalculatorBatch Bi-Spe: ' + biSpeAccount.Name + ' - ' + biSpeAccount.Id);

                for (HierarchyCalculatorBatchService.Node node : hierarchyStructure.get(accountId)) {

                    switch on node.index {
                        when 1 { // père du compte SGL ==> par défaut N1, N2 et N3 sont égaux (pour couvrir le cas d'un seul parent)
                            biSpeAccount.Ascendant_N1__c = node.id;
                            biSpeAccount.Ascendant_N2__c = node.id;
                            biSpeAccount.Ascendant_N3__c = node.id;

                        }

                        when 2 { // grand père du compte SGL ==>  N2 et N3 sont égaux (pour couvrir le cas dd'une hierarchie sur à 2 niveaux)
                            biSpeAccount.Ascendant_N2__c = node.id;
                            biSpeAccount.Ascendant_N3__c = node.id;
                        }

                        when else { // tous les niveaux plus haut de hierarchie
                            biSpeAccount.Ascendant_N3__c = node.id;
                        }
                    }

                    if (node.estN2) {
                        topLevelEstN2Index = node.index - 1;
                    }
                    System.debug('====================> ' + node.index + ' - ' + node.accountName + ' - ' + node.estN2 + ' - ' + node.Id);

                }
                System.debug('====================> top level EstN2 array index: ' + topLevelEstN2Index + ' - Hierarchy Level: ' + (topLevelEstN2Index + 1));

                if (topLevelEstN2Index != -1) {
                    // N2 est remplacé par le noeud EstN2 de plus haut niveau s'il existe (index <> -1)
                    HierarchyCalculatorBatchService.Node topLevelEstN2 = hierarchyStructure.get(accountId)[topLevelEstN2Index];
                    System.debug('======================> ' + topLevelEstN2.index + ' - ' + topLevelEstN2.accountName + ' - ' + topLevelEstN2.estN2 + ' - ' + topLevelEstN2.Id);

                    biSpeAccount.Ascendant_N2__c = topLevelEstN2.Id;
                }

                System.debug('========================> Ascendant_N1__c: ' + biSpeAccount.Ascendant_N1__c);
                System.debug('========================> Ascendant_N2__c: ' + biSpeAccount.Ascendant_N2__c);
                System.debug('========================> Ascendant_N3__c: ' + biSpeAccount.Ascendant_N3__c);

                nbrParentPopulated++;
                totalBiSpec++;
                executionReport = HierarchyCalculatorBatchService.addLineToReport(biSpeAccount, null, executionReport, false, null);

                accountsToUpdate.add(biSpeAccount);
            }
        }

        System.debug('========================> HierarchyCalculatorBatch accountsToUpdate: ' + accountsToUpdate);
        if (!accountsToUpdate.isEmpty()) {

            List<Database.SaveResult> saveResults = Database.update(accountsToUpdate, false);

            for (Integer i=0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                if (!sr.isSuccess()) {
                    nbrErrors++;
                    String message = '';

                    for (Database.Error err : sr.getErrors()) { message += '|' + err.getMessage(); }
                    System.debug('======================== HierarchyCalculatorBatch Update ERROR: ' + message);
                    errorReport = HierarchyCalculatorBatchService.addLineToReport(accountsToUpdate[i], message, errorReport, true, null);
                }
            }
        }
    }

    /**
    * Méthode de l'interface Batchable exécutée à la fin de tous paquets du batch
    * @param bc contexte d'exécution du batch
    */
    global void finish(Database.BatchableContext bc) {

        System.debug('=============== HierarchyCalculatorBatch buildHierarchyStructure Fin à  : ' + Datetime.now());
        System.debug('=============== HierarchyCalculatorBatch # Errors  : ' + nbrErrors);
        System.debug('=============== HierarchyCalculatorBatch # Parent Null  : ' + nbrParentNull);
        System.debug('=============== HierarchyCalculatorBatch # Parent Populated  : ' + nbrParentPopulated);
        System.debug('=============== HierarchyCalculatorBatch # Comptes Bi Spec Traités  : ' + totalBiSpec);
        System.debug('=============== HierarchyCalculatorBatch FIN EXECUTION');

        if (batchParams.Generate_Error_Report__c) { HierarchyCalculatorBatchService.createReport(errorReport, true); }
        if (batchParams.Generate_Exec_Report__c) { HierarchyCalculatorBatchService.createReport(executionReport, false); }


        if (batchParams.Bypass_VR__c) {
            currentUser.Tech_By_Pass_VR__c = false;
            update currentUser;
        }
    }

    /**
    * Méthode de l'interface schedulable permettant l'exécution de code Apex lorsque le schedulable tourne.
     * Ici nous appelons l'exécution du batch
    * @param ctx econtexte d'exécution du schedulable
    */
    global void execute(SchedulableContext ctx) {
        Id batchId = Database.executeBatch(new HierarchyCalculatorBatch());
        System.debug('Scheduled batchjob: ' + batchId);
    }

    /**
    * Méthode permettant de scheduler l'éxecution quotidienne du batch à l'heure souhaitée (interface Schedulable)
    * @param runningHour entier représentant l'heure à laquelle le batch doit s'exécuter
    * @return job id schedulé
    */
    global static String scheduleThis(Integer runningHour) {
        HierarchyCalculatorBatch job = new HierarchyCalculatorBatch();
        // Run job every day at 3 AM
        String schedule = '0 0 ' + runningHour + ' * * ?';
        String batchName = 'HierarchyCalculatorBatch - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;
    }



}