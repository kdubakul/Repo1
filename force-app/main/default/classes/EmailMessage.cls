public class EmailMessage {
    
    private static Set<Id> accIdList; //store account ids
    private static Set<Id> oppIdList; //store opportunity ids
    private static Map<Id,List<id>> accTeamRoleMap = new Map<Id,List<id>>();  //to store accountid and account team role 
    private static Map<Id,List<id>> oppTeamRoleMap = new Map<Id,List<Id>>(); //to store opportunityid and opportunity team role
    private static Map<Id,Map<String,String>> teamRoleMap = new Map<Id,Map<String,String>>(); //to store contactid role (manaeger, lead, team lead) and employee's email
    private static Map<Id,Set<String>> emailsToSend = new Map<Id,Set<String>>(); // to store contactId and set of emails to send
    private static Map<Id, Id> accOptyConMap = new Map<Id, Id>(); //to store contactId and (account team role id or opportunity team role)
    private static String domainURL = label.org_url; //get the domain url from custom label
    private static Map<Id,String> accRoles = new Map<Id,String>();
    private static Map<List<String>,List<String>> reviewerMap = new Map<List<String>,List<String>>();
    private static List<String> roles;
    private static List<String> acceptedTeamRoles = getAcceptedTeamRoles();

    private static List<String> getAcceptedTeamRoles(){
        String roleNames = ContactReviewer__c.getInstance('Accepted Roles').config_value__c;
        List<String> acceptedRoles = roleNames.split(',');
        System.debug(acceptedRoles);
        return acceptedRoles;
    }
    
    public static void sendEmail(List<Contact> conList){
        
        accIdList = new Set<Id>();
        oppIdList = new Set<Id>();
        for(contact con : conList)
        {
            if(con.accountId != null)
            {
                accIdList.add(con.AccountId); // adding account ids to list
            }
            if(con.Opportunity__c != null)
            {
                oppIdList.add(con.Opportunity__c);  // adding opportunity ids to list
            }
        }
        
        //account team roles to put into accTeamRoleMap, AccountId as key and list of account team role ids as values
        for(Account_Team_Role__c  accTeamRole: [SELECT Id, Account_Name__c FROM Account_Team_Role__c WHERE Account_Name__c IN :accIdList]){
            if(!accTeamRoleMap.containsKey(accTeamRole.Account_Name__c)){
                accTeamRoleMap.put(accTeamRole.Account_Name__c,new List<Id>());
            }
            accTeamRoleMap.get(accTeamRole.Account_Name__c).add(accTeamRole.Id);
        }
        
        //account team roles to put into oppTeamRoleMap, Opportunity as key and list of opportunity team role ids as values
        for(Opportunity_Team_Role__c  oppTeamRole: [SELECT Id,Opportunity_Name__c FROM Opportunity_Team_Role__c WHERE Opportunity_Name__c IN :oppIdList]){
            if(!oppTeamRoleMap.containsKey(oppTeamRole.Opportunity_Name__c)){
                oppTeamRoleMap.put(oppTeamRole.Opportunity_Name__c,new List<Id>());
            }
            oppTeamRoleMap.get(oppTeamRole.Opportunity_Name__c).add(oppTeamRole.Id);
        }
        System.debug(' accTeamRoleMap -- > '+accTeamRoleMap);
        System.debug(' oppTeamRoleMap ---> '+oppTeamRoleMap);
        
        for(contact con : conList){
            
            if(con.accountId != null && accTeamRoleMap.containsKey(con.AccountId)){ //checking if accountid having account team roles and putting into accOptyConMap with contactid as key and account team role id as values
                accOptyConMap.put(con.Id, con.AccountId);
            }else if(con.Opportunity__c != null && oppTeamRoleMap.containsKey(con.Opportunity__c)){ //checking if opty having opportunity team roles and putting into accOptyConMap with contactid as key and oppotunity team role id as values
                accOptyConMap.put(con.Id, con.Opportunity__c);
            }
        }
        System.debug('accOptyConMap -- > '+accOptyConMap);
        System.debug('accOptyConMap.values() --> '+accOptyConMap.values());
        
        //teamRoleMap with account / opportunity id as key and employee's email as value
        for(Account_Team_Role__c  accTeamRole: [SELECT Id, Account_Name__c, Account_Role__c,Reviewer_Name__c, Employee__c,Employee__r.email__c FROM Account_Team_Role__c WHERE Account_Name__c IN :accOptyConMap.values() and Account_Role__c in :acceptedTeamRoles]){
            if(!teamRoleMap.containsKey(accTeamRole.Account_Name__c)){
                teamRoleMap.put(accTeamRole.Account_Name__c,new Map<String,String>());
            }
            teamRoleMap.get(accTeamRole.Account_Name__c).put(accTeamRole.Account_Role__c, accTeamRole.Employee__r.email__c);
        }
        //teamRoleMap with account / opportunity id as key and employee's email as value
        for(Opportunity_Team_Role__c  oppTeamRole: [SELECT Id, Opportunity_Role__c, Reviewer__c, Opportunity_Name__c, Employee__c,Employee__r.email__c FROM Opportunity_Team_Role__c WHERE Opportunity_Name__c IN :accOptyConMap.values() and Opportunity_Role__c in :acceptedTeamRoles]){
            if(!teamRoleMap.containsKey(oppTeamRole.Opportunity_Name__c)){
                teamRoleMap.put(oppTeamRole.Opportunity_Name__c,new Map<String,String>());
            }
            teamRoleMap.get(oppTeamRole.Opportunity_Name__c).put(oppTeamRole.Opportunity_Role__c, oppTeamRole.Employee__r.email__c);
        }
        System.debug('teamRoleMap--> '+teamRoleMap);
        
        //getting custom settings values from ContactReviewer__c
        for(ContactReviewer__c rev : [select id, name, config_value__c from ContactReviewer__c order by createdDate desc]){
            reviewerMap.put(rev.Name.split(','),rev.config_value__c.split(','));
        }
        System.debug('reviewerMap--> '+reviewerMap);
        
        //emailsToSend map with contactid as key and employee's email as as values from team roles.
        for(Id key : accOptyConMap.keySet() ){
            roles = new List<String>(teamRoleMap.get(accOptyConMap.get(key)).keySet());
            roles.sort();
            System.debug(roles + ' --- ' +reviewerMap.get(roles));
            for(String str : reviewerMap.get(roles)){
                System.debug('str--> '+str+ ' teamRoleMap.get(accOptyConMap.get(key)).get(str)-->'+teamRoleMap.get(accOptyConMap.get(key)).get(str));
                if(!emailsToSend.containsKey(key)){
                    emailsToSend.put(key,new Set<String>());
                }
                emailsToSend.get(key).add(teamRoleMap.get(accOptyConMap.get(key)).get(str));
            }
        }
        System.debug('emailsToSend ---> '+emailsToSend);
        sendMail(emailsToSend, conList);
    }
    
    public static void sendMail(Map<Id, Set<String>> emailsToSend, List<Contact> conList){
        
        List<Messaging.SingleEmailMessage> masterListMails = new List<Messaging.SingleEmailMessage>();
        
        for(Contact con : [Select id, name, email, Reviewer__c, Reviewer__r.Name, Status__c,createdby.email from Contact where id in: emailsToSend.keySet()]){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
            String subject = 'Contact '+con.Name+ ' Rejected';
            email.setSubject(subject);
            String body = 'Hi '+con.Reviewer__r.Name+',<br/><br/>';
            body+='Contact has been moved to '+con.Status__c+' for the following reason(s):<br/><br/>';
            body+='Please <a href="'+domainURL+con.Id+'">Click Here</a> to view contact <br/><br/><br/>';
            body+='Thanks';
            System.debug('body --> '+body);
            email.setHtmlBody(body);
            email.setSenderDisplayName('No Reply');
            List<String> toAddresses = new List<String>();
            if(emailsToSend.get(con.Id) != null){
                toAddresses.addAll(emailsToSend.get(con.Id));
            }else{
                toAddresses.add(con.createdBy.email);
            }
            System.debug('toAddresses ---> '+toAddresses);
            email.setToAddresses(toAddresses);
            masterListMails.add(email);
        }
        System.debug('masterListMails--> '+masterListMails);
        
        if(masterListMails.size() > 0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(masterListMails);
            
            for(Messaging.SendEmailResult result : results){
                if(result.success ){
                    System.debug('Email Sent Successfully');
                } else{
                    System.debug('Sending Email Failed. Errors '+result.errors + '--- '+result.errors[0].message );
                }
            }
            
        }
    }
}