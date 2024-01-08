/**
 * @description       : Classe de test pour la classe HierarchyCalculatorBatchService
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 12-05-2022
 * @last modified by  : Michaël Cabaraux
**/

@IsTest
private class HierarchyCalculateurBatchServiceTest {


    @IsTest
    static void testBuildHierarchyStructure() {

        Id recTypeEtablissemnt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Etablissement').getRecordTypeId();
        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        Account topLevel = new Account(
                Name = 'Top Level',
                RecordTypeId = recTypeEtablissemnt
        );
        insert topLevel;

        Account level10 = new Account(
                Name = 'Level 10',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = topLevel.Id
        );
        insert level10;

        Account level9 = new Account(
                Name = 'Level 9',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level10.Id,
                Est_Niveau_N2__c = true
        );
        insert level9;

        Account level8 = new Account(
                Name = 'Level 8',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level9.Id
        );
        insert level8;

        Account level7 = new Account(
                Name = 'Level 7',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level8.Id,
                Est_Niveau_N2__c = true
        );
        insert level7;

        Account level6 = new Account(
                Name = 'Level 6',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level7.Id
        );
        insert level6;

        Account level5 = new Account(
                Name = 'Level 5',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level6.Id
        );
        insert level5;

        Account level4 = new Account(
                Name = 'Level 4',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level5.Id,
                Est_Niveau_N2__c = true
        );
        insert level4;

        Account level3 = new Account(
                Name = 'Level 3',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level4.Id
        );
        insert level3;

        Account level2 = new Account(
                Name = 'Level 2',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level3.Id,
                Est_Niveau_N2__c = true
        );
        insert level2;

        Account level1 = new Account(
                Name = 'Level 1',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = level2.Id
        );
        insert level1;

        //Bi-Spec Account
        Account biSpe = new Account(
                Name = 'BiSpeR1',
                RecordTypeId = recTypeBiSpe,
                ParentId = level1.Id
        );
        insert biSpe;

        Account accountToSend = [
                SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c, ParentId, Parent.Est_Niveau_N2__c, Parent.Name, Name,Parent.ParentId,
                    Parent.Parent.Name, Parent.Parent.Est_Niveau_N2__c,Parent.Parent.ParentId, Parent.Parent.Parent.Name,
                    Parent.Parent.Parent.Est_Niveau_N2__c,Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.Name,
                    Parent.Parent.Parent.Parent.Est_Niveau_N2__c,Parent.Parent.Parent.Parent.ParentId,Parent.Parent.Parent.Parent.Parent.Name,
                    Parent.Parent.Parent.Parent.Parent.Est_Niveau_N2__c, Est_Niveau_N2__c
                FROM Account
                WHERE Id = :biSpe.Id];

        Map<Id, List<HierarchyCalculatorBatchService.Node>> hierarchy = HierarchyCalculatorBatchService.buildHierarchyStructure(new Set<Account>{accountToSend});
        System.debug('================================== TEST TEST HierarchyCalculateurBatchServiceTest testNoParent hierarchy: ' + hierarchy);


        System.assertEquals(11, hierarchy.get(biSpe.Id).size());
        System.assertEquals(level1.Id, hierarchy.get(biSpe.Id)[0].Id);
        System.assertEquals(topLevel.Id, hierarchy.get(biSpe.Id)[10].Id);
    }

    @IsTest
    static void testReportFunctionalities() {

        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        Account biSpe = new Account(
                Name = 'BiSpeR1',
                RecordTypeId = recTypeBiSpe,
                Ascendant_N1__c = null,
                Ascendant_N2__c = null,
                Ascendant_N3__c = null
        );
        insert biSpe;

        String reportLine = HierarchyCalculatorBatchService.addLineToReport(biSpe, null, '', false, null);
        String errorLine = HierarchyCalculatorBatchService.addLineToReport(biSpe, 'Error', '', true, null);

        HierarchyCalculatorBatchService.createReport(reportLine, false);
        HierarchyCalculatorBatchService.createReport(errorLine, true);


        List<ContentVersion> contentVersions = new List<ContentVersion>([SELECT Id, PathOnClient FROM ContentVersion]);
        System.debug('================================== TEST TEST testReportFunctionalities contentVersions: ' + contentVersions);
        System.assertEquals(2, contentVersions.size());

    }
}