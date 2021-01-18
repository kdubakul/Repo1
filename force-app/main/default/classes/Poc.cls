public without sharing class Poc {

    @AuraEnabled(cacheable=true)
    public static List<Account> findAccounts() {
        return [SELECT Name, AccountNumber from Account Limit 10];
    }

}