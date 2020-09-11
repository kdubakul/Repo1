trigger ContractReviewverTrigger on Contact (before insert,before update, after insert, after update) {
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            ContractReviewverTriggerHelper.beforeInsert(Trigger.New);
        }
        if(Trigger.isUpdate)
        {
            ContractReviewverTriggerHelper.beforeUpdate(Trigger.New,trigger.oldMap);
            // yet to start work on it
        }
    }
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            ContractReviewverTriggerHelper.afterInsert(Trigger.New);
        }
        if(Trigger.isUpdate){
            ContractReviewverTriggerHelper.afterUpdate(Trigger.New, Trigger.oldMap);    
        }
    }
}