@isTest
public class ContractReviewverTriggerTest {
    
    @testSetup static void setup() {
        
        List<ContactReviewer__c> setting = new List<ContactReviewer__c>();
        setting.add(new ContactReviewer__c(Name = 'Accepted Roles',config_Value__c = 'Lead,Manager,Team Lead'));
        setting.add(new ContactReviewer__c(Name = 'Lead',config_Value__c = 'Lead'));
        setting.add(new ContactReviewer__c(Name = 'Lead,Manager',config_Value__c = 'Lead,Manager'));
        setting.add(new ContactReviewer__c(Name = 'Lead,Manager,Team Lead',config_Value__c = 'Lead,Manager'));
        setting.add(new ContactReviewer__c(Name = 'Lead,Team Lead',config_Value__c = 'Lead'));
        setting.add(new ContactReviewer__c(Name = 'Manager',config_Value__c = 'Manager'));
        setting.add(new ContactReviewer__c(Name = 'Manager,Team Lead',config_Value__c = 'Manager,Team Lead'));
        setting.add(new ContactReviewer__c(Name = 'Team Lead',config_Value__c = 'Team Lead'));
        insert setting;
        List<String> roles = new List<String>{'Manager','Team Lead','Lead','Tech Lead'};
		List<String> emails = new List<String>{'test1@test.com','test2@test.com','test3@test.com','test4@test.com'};
        
        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for(Integer i=0;i<=3;i++) {
            testAccts.add(new Account(Name = 'TestAcct'+i));
        }
        insert testAccts;
        
        List<Employee__c> employees = new List<Employee__c>();
        for(Integer i=0;i<=3;i++){
            Employee__c emp = new Employee__c();
            emp.Name = 'Test Emp '+i;
            emp.Email__c = emails[i];
            employees.add(emp);
        }
        insert employees;
        List<Account_Team_Role__c> accountTeamRoles = new List<Account_Team_Role__c>();
        for(Account acc : testAccts){
            for(Integer i=0; i<=3;i++){
                Account_Team_Role__c atr = new Account_Team_Role__c();
                atr.name = 'Testing '+roles[i];
                atr.Account_Role__c = roles[i];
                atr.Account_Name__c = acc.id;
                atr.Employee__c = employees[i].Id;
                atr.Reviewer_Name__c = userinfo.getUserId();
                accountTeamRoles.add(atr);
            }
        }
        insert accountTeamRoles;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        for(Integer i = 0; i<=3; i++){
            opportunities.add(new Opportunity(name = 'Test opty '+i,
                                              closedate = System.today() + 15,
                                              StageName = 'Closed Won'));
        }
        insert opportunities;
        
        List<Opportunity_Team_Role__c> optyTeamRoles = new List<Opportunity_Team_Role__c>();
        for(Opportunity opty : opportunities){
            for(Integer i=0; i<=3; i++){
                optyTeamRoles.add(new Opportunity_Team_Role__c(name = 'Testing '+roles[i],
                                                               Opportunity_Name__c = opty.Id,
                                                               Opportunity_Role__c = roles[i],
                                                               Employee__c = employees[i].id,
                                                               Reviewer__c = userinfo.getUserId()));
            }
        }
        insert optyTeamRoles;
        
    }
    
    @isTest static void testContactInsert() {
        // code_block
        
        List<Account> accs = [select id from account];
        List<Opportunity> opty = [select id from opportunity];
        
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i<=1; i++){
            contacts.add(new Contact(lastName = 'Test Con '+i, accountId = accs[i].id, Status__c = 'In Progress'));
        }
        for(Integer i=2;i<=3;i++){
            contacts.add(new Contact(lastName = 'Test Con '+i, Opportunity__c = opty[i].id, Status__c = 'In Progress'));
        }
        contacts.add(new Contact(lastName = 'Test Con 4', Reviewer__c = userinfo.getUserId(), Status__c = 'In Progress'));
        insert contacts;
        
    }
    
    @isTest static void testContactUpdate() {
        // code_block
        List<Account> accs = [select id from account];
        List<Opportunity> opty = [select id from opportunity];
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i<=1; i++){
            contacts.add(new Contact(lastName = 'Test Con '+i, accountId = accs[i].id));
        }
        for(Integer i=2;i<=3;i++){
            contacts.add(new Contact(lastName = 'Test Con '+i, Opportunity__c = opty[i].id));
        }
        contacts.add(new Contact(lastName = 'Test Con 4', Reviewer__c = userinfo.getUserId()));
        insert contacts;
        
        List<Contact> consToUpdate = new List<Contact>();
        consToUpdate.add(new Contact(id = contacts[0].id, status__c = 'In Progress'));
        consToUpdate.add(new Contact(id = contacts[1].id, status__c = 'In Progress', AccountId = accs[0].Id));
        consToUpdate.add(new Contact(id = contacts[4].id, status__c = 'In Progress', Opportunity__c = opty[1].Id));
        update consToUpdate;
    }

}