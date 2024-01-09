/**
 * Created by Michael on 08-07-22.
 */

global class CV_DiscountCollegeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {

    private static final String CONFIGURATION_NAME = 'Discount_College_Batch';

    private CV_Batch_Settings__mdt batchSettings;


    global Database.querylocator start(Database.BatchableContext bc) {

        this.batchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c, Default_Sender_Address_Id__c,
                        Email_Template_Id__c, Paid_Email_Template_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' FROM Account';
        query += ' WHERE Remise_REPLAY_Cerbavet_College__c = true AND (Remise_REPLAY__c <> null AND Remise_REPLAY__c <> 0)';

        System.debug('============================ CV_DiscountCollegeBatch start query : ' + query);

        Database.QueryLocator queryLocator = Database.getQueryLocator(query);

        return queryLocator;
    }


    global void execute(Database.BatchableContext bc, List<Account> accounts) {

        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        Map<Id, Account> accountsMap = new Map<Id,Account>(accounts);
        Map<Id, Decimal> discountsByAccountIds = new Map<Id, Decimal>();
        Set<Id> invoiceAccountIds = new Set<Id>();

        System.debug('======================= CV_DiscountCollegeBatch accountsMap: ' + accountsMap);

        List<OrderItem> orderItems = new List<OrderItem>([
                SELECT Id, Product2.ProductCode, Order.AccountId, blng__OverrideBillableUnitPrice__c, UnitPrice, ListPrice, SBQQ__QuotedListPrice__c, Order.blng__BillingAccount__c
                FROM OrderItem
                WHERE Order.AccountId in :accounts
                AND Product2.ProductCode = 'REPLAYS'
                AND SBQQ__Activated__c = true
        ]);

        for (OrderItem orderItem :orderItems) {
            System.debug('======================= CV_DiscountCollegeBatch orderItem: ' + orderItem);
            if (Order.blng__BillingAccount__c != null) {
                invoiceAccountIds.add(orderItem.Order.blng__BillingAccount__c);
            } else {
                invoiceAccountIds.add(orderItem.Order.AccountId);
            }
        }
        System.debug('======================= CV_DiscountCollegeBatch invoiceAccountIds: ' + invoiceAccountIds);

        if (Test.isRunningTest()) {invoiceAccountIds = accountsMap.keySet(); }

        for (AggregateResult aggregateResult : [
                SELECT blng__Account__c, SUM(blng__TotalAmount__c) total
                FROM blng__Invoice__c
                WHERE blng__Account__c in :invoiceAccountIds
                AND blng__InvoiceDate__c = LAST_MONTH
                GROUP BY blng__Account__c]) {

            String accountId = (String)aggregateResult.get('blng__Account__c');
            Decimal totalInvoices = (Decimal)aggregateResult.get('total');
            Decimal pourcentage = accountsMap.get(accountId).Remise_REPLAY__c;

            Decimal discountAmount = totalInvoices * pourcentage / 100;

            discountsByAccountIds.put(accountId, discountAmount);
        }

        System.debug('======================= CV_DiscountCollegeBatch discountsByAccountIds: ' + discountsByAccountIds);


        for (OrderItem orderItem : orderItems) {

            Account account = accountsMap.get(orderItem.Order.AccountId);

            if (account != null) {
//                Decimal pourcentage = account.Remise_REPLAY__c;

                if (discountsByAccountIds.containsKey(account.Id) || discountsByAccountIds.containsKey(orderItem.Order.blng__BillingAccount__c)) {

                    Decimal discount;
                    if (orderItem.Order.blng__BillingAccount__c != null) {
                        discount = discountsByAccountIds.get(orderItem.Order.blng__BillingAccount__c);
                    } else {
                        discount = discountsByAccountIds.get(account.Id);
                    }

                    System.debug('======================= CV_DiscountCollegeBatch pourcentage: ' + discount);
//                    Decimal price = orderItem.SBQQ__QuotedListPrice__c - (orderItem.SBQQ__QuotedListPrice__c * pourcentage /100);

                    Decimal price = orderItem.SBQQ__QuotedListPrice__c < discount ? 0 : orderItem.SBQQ__QuotedListPrice__c - discount;

                    System.debug('======================= CV_DiscountCollegeBatch price: ' + price);

                    OrderItem orderItemToUpdate = new OrderItem(
                            Id = orderItem.Id,
                            blng__TaxStatus__c = 'Queued',
                            blng__OverrideBillableUnitPrice__c = price,
                            UnitPrice = price
                    );

                    orderItemsToUpdate.add(orderItemToUpdate);
                }
            }
        }

        SBQQ.TriggerControl.disable();
        if (!orderItemsToUpdate.isEmpty()) {
            Database.SaveResult[] resultsCn = Database.update(orderItemsToUpdate, false);

            for (Integer i=0; i < resultsCn.size(); i++) {
                Database.SaveResult sr = resultsCn[i];
                if (!sr.isSuccess()) {

                    for (Database.Error err : sr.getErrors()) {
                        System.debug('============================= ERROR : ' + err);
                    }
                }
            }
        }

        SBQQ.TriggerControl.enable();


    }

    global void finish(Database.BatchableContext bc) {

        System.debug('============================ CV_DiscountCollegeBatch FINISHED');

    }


    global void execute(SchedulableContext sc) {

        CV_Batch_Settings__mdt BatchSettings = [
                SELECT Active__c, Batch_Scope_Size__c, Default_Account_Id__c
                FROM CV_Batch_Settings__mdt
                WHERE DeveloperName = :CONFIGURATION_NAME
        ];


        CV_DiscountCollegeBatch batch = new CV_DiscountCollegeBatch();
        Database.executeBatch(batch,Integer.valueOf(batchSettings.Batch_Scope_Size__c));

    }


    global static String scheduleThis(String schedule) {

        CV_DiscountCollegeBatch job = new CV_DiscountCollegeBatch();
        String batchName = 'CV_DiscountCollegeBatch - ' + DateTime.now().format('YYYYMMDDHHmmss');
        String jobId = System.schedule(batchName, schedule, job);
        return jobId;

    }

}