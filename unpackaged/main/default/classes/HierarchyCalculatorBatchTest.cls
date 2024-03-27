/**
 * @description       : Classe de test pour la classe HierarchyCalculatorBatch
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 10-05-2022
 * @last modified by  : Michaël Cabaraux
**/

@IsTest
private class HierarchyCalculatorBatchTest {


    @IsTest
    static void testNoParentR2() {

        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        deactivateVR();

        //Bi-Spec Account
        Account biSpe = new Account(
                Name = 'BiSpeR1',
                RecordTypeId = recTypeBiSpe
        );
        insert biSpe;

        Test.startTest();

        Database.executeBatch(new HierarchyCalculatorBatch());

        Test.stopTest();

        biSpe = [SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c FROM Account WHERE Id = :biSpe.Id];

        //No Parent ==> AN1, AN2, AN3 == null
        System.assertEquals(null, biSpe.Ascendant_N1__c);
        System.assertEquals(null, biSpe.Ascendant_N2__c);
        System.assertEquals(null, biSpe.Ascendant_N3__c);

//        activateVR();
    }

    @IsTest
    static void testOneParentR3() {

        Id recTypeEtablissemnt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Etablissement').getRecordTypeId();
        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        deactivateVR();

        Account topLevel = new Account(
                Name = 'Top Level',
                RecordTypeId = recTypeEtablissemnt
        );
        insert topLevel;

        //Bi-Spec Account
        Account biSpe = new Account(
                Name = 'BiSpeR1',
                RecordTypeId = recTypeBiSpe,
                ParentId = topLevel.Id
        );
        insert biSpe;

        Test.startTest();

        Database.executeBatch(new HierarchyCalculatorBatch());

        Test.stopTest();

        biSpe = [SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c FROM Account WHERE Id = :biSpe.Id];

        //NOne Parent ==> AN1 = AN2 = AN3 == Parent Id
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N1__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N2__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N3__c);

//        activateVR();

    }

    @IsTest
    static void testTwoParentsR4() {

        Id recTypeEtablissemnt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Etablissement').getRecordTypeId();
        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        deactivateVR();

        Account topLevel = new Account(
                Name = 'Top Level',
                RecordTypeId = recTypeEtablissemnt
        );
        insert topLevel;

        Account level1 = new Account(
                Name = 'Level 1',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = topLevel.Id
        );
        insert level1;

        //Bi-Spec Account
        Account biSpe = new Account(
                Name = 'BiSpeR1',
                RecordTypeId = recTypeBiSpe,
                ParentId = level1.Id
        );
        insert biSpe;

        Test.startTest();

        Database.executeBatch(new HierarchyCalculatorBatch());

        Test.stopTest();

        biSpe = [SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c FROM Account WHERE Id = :biSpe.Id];

        //2Parents ==> BiSpe --> Level 1 --> Top Level
        //AN1 == Level 1
        //AN2 == Top Level
        //AN3 == Top Level
        System.assertEquals(level1.Id, biSpe.Ascendant_N1__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N2__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N3__c);

//        activateVR();

    }


    @IsTest
    static void testR1BaseNoEstN2() {

        Id recTypeEtablissemnt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Etablissement').getRecordTypeId();
        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        deactivateVR();

        Account topLevel = new Account(
                Name = 'Top Level',
                RecordTypeId = recTypeEtablissemnt
        );
        insert topLevel;

        Account levelMid = new Account(
                Name = 'Level Mid',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = topLevel.Id
        );
        insert levelMid;

        Account level2 = new Account(
                Name = 'Level 2',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = levelMid.Id
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

        Test.startTest();

        Database.executeBatch(new HierarchyCalculatorBatch());

        Test.stopTest();

        biSpe = [SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c FROM Account WHERE Id = :biSpe.Id];

        //R1 Multilevel No EstN2 ==> BiSpe --> Level 1 --> Level 2 --> Level Mid --> Top Level
        //AN1 == Level 1
        //AN2 == Level 2
        //AN3 == Top Level

        System.assertEquals(level1.Id, biSpe.Ascendant_N1__c);
        System.assertEquals(level2.Id, biSpe.Ascendant_N2__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N3__c);

//        activateVR();

    }

    @IsTest
    static void testR1BaseOneEstN2() {

        Id recTypeEtablissemnt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Etablissement').getRecordTypeId();
        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        deactivateVR();

        Account topLevel = new Account(
                Name = 'Top Level',
                RecordTypeId = recTypeEtablissemnt
        );
        insert topLevel;

        Account levelMid = new Account(
                Name = 'Level Mid',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = topLevel.Id,
                Est_Niveau_N2__c = true
        );
        insert levelMid;

        Account level2 = new Account(
                Name = 'Level 2',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = levelMid.Id
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

        Test.startTest();

        Database.executeBatch(new HierarchyCalculatorBatch());

        Test.stopTest();

        biSpe = [SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c FROM Account WHERE Id = :biSpe.Id];

        //R1 Multilevel with One EstN2 ==> BiSpe --> Level 1 --> Level 2 --> Level Mid EstN2--> Top Level
        //AN1 == Level 1
        //AN2 == Level Mid (EstN2)
        //AN3 == Top Level

        System.assertEquals(level1.Id, biSpe.Ascendant_N1__c);
        System.assertEquals(levelMid.Id, biSpe.Ascendant_N2__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N3__c);

//        activateVR();

    }

    @IsTest
    static void testR1BaseMultiEstN2() {

        Id recTypeEtablissemnt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Etablissement').getRecordTypeId();
        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        deactivateVR();

        Account topLevel = new Account(
                Name = 'Top Level',
                RecordTypeId = recTypeEtablissemnt
        );
        insert topLevel;

        Account level4 = new Account(
                Name = 'Level 4',
                RecordTypeId = recTypeEtablissemnt,
                ParentId = topLevel.Id,
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

        Test.startTest();

        Database.executeBatch(new HierarchyCalculatorBatch());

        Test.stopTest();

        biSpe = [SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c FROM Account WHERE Id = :biSpe.Id];

        //R1 Multilevel EstN2 ==> BiSpe --> Level 1 --> Level 2 EstN2--> Level 3 --> Level 4 EstN2 --> Top Level
        //AN1 == Level 1
        //AN2 == Level 4
        //AN3 == Top Level

        System.assertEquals(level1.Id, biSpe.Ascendant_N1__c);
        System.assertEquals(level4.Id, biSpe.Ascendant_N2__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N3__c);

//        activateVR();

    }

    @IsTest
    static void testHighLevelHierarchyBiggerThan5() {

        Id recTypeEtablissemnt = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Etablissement').getRecordTypeId();
        Id recTypeBiSpe = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Compte Client SGL (BI Spé)').getRecordTypeId();

        deactivateVR();

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

        Test.startTest();

        Database.executeBatch(new HierarchyCalculatorBatch());

        Test.stopTest();

        biSpe = [SELECT Id, Ascendant_N1__c, Ascendant_N2__c, Ascendant_N3__c FROM Account WHERE Id = :biSpe.Id];

        //R1 Multilevel > 10 ==> BiSpe --> .. --> Level 10 --> Top Level
        //AN1 == Level 1
        //AN2 == Level 9 (Last EstN2 of hierarchy)
        //AN3 == Top Level

        System.assertEquals(level1.Id, biSpe.Ascendant_N1__c);
        System.assertEquals(level9.Id, biSpe.Ascendant_N2__c);
        System.assertEquals(topLevel.Id, biSpe.Ascendant_N3__c);

//        activateVR();

    }

    @IsTest
    static void testScheduling() {

        System.Test.startTest();
        String scheduleId = HierarchyCalculatorBatch.scheduleThis(4);

        // GEt the information from the CronTrigger API Object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :scheduleId];

        // Verify the expressions are the same
        System.assertEquals('0 0 4 * * ?', ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        System.Test.stopTest();

    }


    private static void deactivateVR() {

        User currentUser = new User(
                Id = UserInfo.getUserId(),
                Tech_By_Pass_VR__c = true
        );
//        update currentUser;

    }
}