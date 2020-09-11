public class ContractReviewverTriggerHelper {
    
    private static Set<Id> accIdList;
    private static Set<Id> oppIdList;
    
    private static Map<Id,Account_Team_Role__c> accIdVsUserIdManagerMap = new Map<Id,Account_Team_Role__c>();
    private static Map<Id,Account_Team_Role__c> accIdVsUserIdLeadrMap = new Map<Id,Account_Team_Role__c>();
    
    private static Map<Id,Opportunity_Team_Role__c> OppIdVsUserIdManagerMap = new Map<Id,Opportunity_Team_Role__c>();
    private static Map<Id,Opportunity_Team_Role__c> OppIdVsUserIdLeadrMap = new Map<Id,Opportunity_Team_Role__c>();
    
    private static List<Contact> sendEmailConList;
    private static List<Contact> updatedConList;
    
    Public static void beforeInsert(List<Contact> conList)
    {
        updateContactReviewer(conList);
        
        
    }
    
    Public static void beforeUpdate(List<Contact> conList,Map<Id,contact> oldconMap)
    {
        updatedConList = new List<Contact>();
        
        for(contact con : conList){
            if(oldconMap.get(con.Id).accountId != con.AccountId || oldconMap.get(con.Id).Opportunity__c != con.Opportunity__c || (oldconMap.get(con.Id).accountId == null && con.AccountId != null)){
                updatedConList.add(con);
            }
        }
        
        if(updatedConList != null && updatedConList.size() > 0){
            updateContactReviewer(updatedConList);
        }
        
        
        
    }
    
    public static void afterInsert(List<Contact> conList){
        sendEmailConList = new List<Contact>();
        for(Contact con : conList){
            if(con.Status__c == 'In Progress' && (con.AccountId != null || con.Opportunity__c != null || con.Reviewer__c != null)){
                sendEmailConList.add(con);
            }
        }
        if(sendEmailConList.size() > 0){
	        EmailMessage.sendEmail(sendEmailConList);
        }
    }
    
    public static void afterUpdate(List<Contact> conList, Map<Id,contact> oldconMap){
        sendEmailConList = new List<Contact>();
        
        for(Contact con : conList){
            if((oldconMap.get(con.Id).Status__c != 'In Progress' && con.Status__c == 'In Progress') ||
              oldconMap.get(con.Id).accountId != con.AccountId || oldconMap.get(con.Id).opportunity__c != con.opportunity__c ||
              oldconMap.get(con.Id).reviewer__c != con.Reviewer__c){
                sendEmailConList.add(con);
            }
        }
        if(sendEmailConList.size() > 0){
            EmailMessage.sendEmail(sendEmailConList);
        }
    }
    
    private static void updateContactReviewer(List<Contact> conList){
        accIdList = new Set<Id>();
        oppIdList = new Set<Id>();
        for(contact con : conList)
        {
            if(con.accountId != null)
            {
                accIdList.add(con.accountId); 
            }
            if(con.Opportunity__c != null)
            {
                oppIdList.add(con.Opportunity__c); 
            }
        }
        
        if(accIdList != null && accIdList.size()>0)
        {
            for(Account_Team_Role__c  accTeamRole: [SELECT Id, Account_Role__c, Reviewer_Name__c, Reviewer_Name__r.Email, Account_Name__c FROM Account_Team_Role__c WHERE Account_Name__c IN :accIdList])
            {
                if(accTeamRole.Account_Role__c == 'Manager')
                {
                    accIdVsUserIdManagerMap.put(accTeamRole.Account_Name__c,accTeamRole);
                }
                if(accTeamRole.Account_Role__c == 'Team Lead')
                {
                    accIdVsUserIdLeadrMap.put(accTeamRole.Account_Name__c,accTeamRole);
                }
            }
        }
        
        if(oppIdList != null && oppIdList.size()>0)
        {
            for(Opportunity_Team_Role__c  oppTeamRole: [SELECT Id, Opportunity_Role__c, Reviewer__c, Reviewer__r.Email, Opportunity_Name__c FROM Opportunity_Team_Role__c WHERE Opportunity_Name__c IN :oppIdList])
            {
                if(oppTeamRole.Opportunity_Role__c == 'Manager')
                {
                    OppIdVsUserIdManagerMap.put(oppTeamRole.Opportunity_Name__c,oppTeamRole);
                }
                if(oppTeamRole.Opportunity_Role__c == 'Team Lead')
                {
                    OppIdVsUserIdLeadrMap.put(oppTeamRole.Opportunity_Name__c,oppTeamRole);
                }
            }
        }
        
        for(contact con : conList)
        {
            if(con.accountId != null  )
            {
                if(!accIdVsUserIdManagerMap.isEmpty() && accIdVsUserIdManagerMap.containsKey(con.accountId))
                {
                    con.Reviewer__c = accIdVsUserIdManagerMap.get(con.accountId).Reviewer_Name__c;
                }
                else
                    if(!accIdVsUserIdLeadrMap.isEmpty() && accIdVsUserIdLeadrMap.containsKey(con.accountId))
                {
                    con.Reviewer__c = accIdVsUserIdLeadrMap.get(con.accountId).Reviewer_Name__c;
                }
            }
            else if(con.Opportunity__c != null)
            {
                if(!OppIdVsUserIdManagerMap.isEmpty() && OppIdVsUserIdManagerMap.containsKey(con.Opportunity__c))
                {
                    con.Reviewer__c = OppIdVsUserIdManagerMap.get(con.Opportunity__c).Reviewer__c;
                }
                else
                    if(!OppIdVsUserIdLeadrMap.isEmpty() && OppIdVsUserIdLeadrMap.containsKey(con.Opportunity__c))
                {
                    con.Reviewer__c = OppIdVsUserIdLeadrMap.get(con.Opportunity__c).Reviewer__c;
                }
            }
        }
    }
    
    
}