/**
 * @description       : Module de serive pour le batch HierarchyCalculatorBatch
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 12-05-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class HierarchyCalculatorBatchService {


    /**
    * Méthode créant l'arbre hiérarchique des comptes BiSpe qui lui sont passés. Chaque niveau de hierarchie est appelé un 'Node'.
     * Chaque noeud contient les infos suivantes:
     * - Id du compte associé
     * - Niveau de la hierarchie
     * - Flag EstN2
     * Afin de limiter le nombre de SOQL on remonte jusque 5 niveau de hierarchie en une fois (max autorisé par SF) -> parent.parent.parent ...
    * @param accounts liste des comptes BiSpe à traiter
    */
    public static Map<Id, List<Node>> buildHierarchyStructure(Set<Account> accounts) {


        System.debug('=============== HierarchyCalculatorBatch buildHierarchyStructure accounts : ' + accounts);
        Map<Id, List<Node>> parentHierarchyBySGLIds = new Map<Id, List<Node>>();

        List<Account> accountsWithMaxParents = new List<Account>(); // Comptes ayant au moins une hierarchie 5 niveau. Il faut faire un autre SOQL pour voir si la hierarchie continue

        for (Account account : accounts) {
            if (account.Parent.Parent.Parent.Parent.ParentId != null) {
                accountsWithMaxParents.add(account);
            }
        }

        System.debug('=============== HierarchyCalculatorBatch buildHierarchyStructure accountsWithMaxParents : ' + accountsWithMaxParents);

        // Completer la hierarchie des comptes au-delà de niveaux
        Map<Id, Account> accountsToReturn = new Map<Id, Account>();
        if (!accountsWithMaxParents.isEmpty()) {
            Map<Id, Account> accountsByAccountIds = new Map<Id, Account>();

            accountsToReturn = retrieveParentHierarchy(accountsWithMaxParents, accountsByAccountIds);
        }


        for (Account account : accounts) {
            if (!parentHierarchyBySGLIds.containsKey(account.Id)) {
                parentHierarchyBySGLIds.put(account.Id, new List<Node>());
            }
            List<Node> parentHierarchy = parentHierarchyBySGLIds.get(account.Id);
            recursiveBuildNode(account.Parent, parentHierarchy, accountsToReturn,1);

        }

        return parentHierarchyBySGLIds;
    }

    /**
    * Méthode récursive permettant de remonter la hierarchie de compte jusqu'au plus haut parent.
     * Afin de limiter le nombre de SOQL on remonte jusque 5 niveau de hierarchie en une fois (max autorisé par SF) -> parent.parent.parent ...
    * @param accountsToCheck liste de comptes pour laquelle il faut remonter dans la hierarchie parent, grand-pârent, ....
    * @param accountsByIds Map relation un id de compte et son objet compte
    * @return liste des comptes de hierarchie > 5
    */
    private static Map<Id, Account> retrieveParentHierarchy(List<Account> accountsToCheck, Map<Id, Account> accountsByIds) {

        Map<Id, Account> accountsToReturn = new Map<Id, Account>();
        Set<Account> accountsToQueryMore = new Set<Account>();
        for (Account Account : accountsToCheck) {
            if (account.Parent.Parent.Parent.Parent.ParentId != null) {
                // Niveau max hierarchique atteind pout un seul SOQL + Parent non vide, il faut remonter la hiérarchie
                accountsToQueryMore.add(account.Parent.Parent.Parent.Parent.Parent);
            }
        }

        System.debug('=============== HierarchyCalculatorBatch retrieveParentHierarchy accountsToQueryMore : ' + accountsToQueryMore);

        if (!accountsToQueryMore.isEmpty()) {

            Map<Id, Account> retrievedAccounts =  new Map<Id, Account>([
                    SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c, ParentId, Parent.Est_Niveau_N2__c, Parent.Name, Name,Parent.ParentId,
                            Parent.Parent.Name, Parent.Parent.Est_Niveau_N2__c,Parent.Parent.ParentId, Parent.Parent.Parent.Name,
                            Parent.Parent.Parent.Est_Niveau_N2__c,Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Name,
                            Parent.Parent.Parent.Parent.Est_Niveau_N2__c,Parent.Parent.Parent.Parent.ParentId,Parent.Parent.Parent.Parent.Parent.Name,
                            Parent.Parent.Parent.Parent.Parent.Est_Niveau_N2__c, Est_Niveau_N2__c
                    FROM Account
                    WHERE Id in : accountsToQueryMore
            ]);

            accountsToReturn.putAll(retrievedAccounts);
            System.debug('=============== HierarchyCalculatorBatch retrieveParentHierarchy retrievedAccounts : ' + retrievedAccounts);

            accountsToReturn.putAll(retrieveParentHierarchy(accountsToReturn.values(), accountsByIds));
        }

        return accountsToReturn;

    }

    /**
    * Méthode récursive permettant de construire la représentant hierarchique, par compte BiSpe, des noeuds. Les query permettant de retrouver tous les parents d'un compte
     * doivent être effectués avant.
    * @param account compte BiSpé pour lequel on construit la hierarchie
    * @param parentHierarchy hierarchie de noeud du client BiSpé
    * @param accountsHighHierarchy liste des comptes avec leurs parents si hierarchie à plus de 5 niveaux
    * @param depth profondeur d'appel hierarchique
    * @return liste des comptes de hierarchie > 5
    */
    private static void recursiveBuildNode(Account account, List<Node> parentHierarchy, Map<Id, Account> accountsHighHierarchy, Integer depth) {

        // On ajoute le parent dans la liste et on entre dans la récurrence tant qu'il a un parent

        System.debug('=============== HierarchyCalculatorBatch recursiveBuildNode parentHierarchy : ' + parentHierarchy);
        System.debug('=============== HierarchyCalculatorBatch recursiveBuildNode depth : ' + depth);
        System.debug('=============== HierarchyCalculatorBatch recursiveBuildNode account : ' + account);
        parentHierarchy.add(new Node(depth, account.Id, account.Name, account.Est_Niveau_N2__c));

        Integer reminder = math.mod(depth, 5); // Un SOQL doit être effectué pour chaque 5 niveau de la hierarchie parents (max 5 niveaux remontés dans la hierarchie par SOQL)
        System.debug('=============== HierarchyCalculatorBatch recursiveBuildNode reminder : ' + reminder);

        if (reminder != 0 && account.ParentId != null) {   // On ne sait pas prendre le parent d'un niveau hiérarchique 5 et plus en direct
            recursiveBuildNode(account.Parent, parentHierarchy, accountsHighHierarchy, ++depth);

        } else if (reminder == 0) { // Tous les multiples de 5 on vérifie que l'on a pas trouver encore un parent dans la hierarchie
            System.debug('=============== HierarchyCalculatorBatch recursiveBuildNode account Id : ' + account.Id);
            if (accountsHighHierarchy.containsKey(account.Id)) {
                Account parentAccount = accountsHighHierarchy.get(account.Id);
                if (parentAccount.Parent != null) {
                    recursiveBuildNode(parentAccount.Parent, parentHierarchy, accountsHighHierarchy, ++depth);
                }
            }
        }
    }

    /**
    * Permet d'ajouter une ligne de rapport (au format csv) aux lignes existantes
    * @param account compte BiSpé
    * @param errorMessage message d'erreur s'il s'agit d'une à ajouter au rapport d'erreurs
    * @param originalContent contenu du rapport avant ajout de la ligne
    * @param isError identitie s'il s'agit d'une ligne d'erreur
    * @param params
    * @return ligne de rapport modifiée
    */
    public static String addLineToReport(Account account, String errorMessage, String originalContent, Boolean isError, List<String> params) {

        String line;

        if (isError) {
            line = account.Name + ',' + account.Id + ',' + errorMessage.replaceAll(',', ' - ') + '\n';
        } else {
            line = account.Name + ',' + account.Id + ',' + account.Ascendant_N1__c + ',' + account.Ascendant_N2__c + ',' + account.Ascendant_N3__c + '\n';
        }

        originalContent += line;

        return originalContent;

    }

    /**
    * Cette méthode créé le fichier csv et le stocke dans en temps qui "file" dans Salesforce
    * @param content contenu du rapport
    * @param isError identitie s'il s'agit d'une ligne d'erreur
    * @param params
    */
    public static void createReport(String content, Boolean isError) {

        String firstLine;
        String title;

        if (isError) {
            firstLine = 'Nom du Compte,Id,Erreur\n';
            title = 'HierarchyBatchCalcultator Rapport d\'erreurs_' + Datetime.now();
        } else {
            firstLine = 'Nom du Compte,Id,Id Ascendant_N1__c, Id Ascendant_N2__c, Id Ascendant_N3__c\n';
            title = 'HierarchyBatchCalcultator Rapport d\'exécution_' + Datetime.now();
        }

        firstLine += content;

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S'; //denotes it resides on Salesforce
        cv.Title = title; //title of the file
        cv.PathOnClient = title + '.csv';
        cv.OwnerId = UserInfo.getUserId();
        cv.VersionData = Blob.valueOf(firstLine);

        insert cv;

    }


    public class Node {

        public Integer index { get; set; }
        public Boolean estN2 { get; set; }
        public String id { get; set; }
        public String accountName { get; set; }

        public Node (Integer index, String Id, String accountName, Boolean estN2) {
            this.index = index;
            this.id = id;
            this.accountName = accountName;
            this.estN2 = estN2;
        }

    }

}