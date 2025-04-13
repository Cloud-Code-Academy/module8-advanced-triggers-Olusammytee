trigger AccountTrigger on Account (before insert, after insert) {
    AccountHelper helper = new AccountHelper();
    
    if (Trigger.isBefore && Trigger.isInsert) {
        helper.setTypeProspect(Trigger.new);
        helper.addressCopy((List<Account>)Trigger.new);
        helper.setRating((List<Account>)Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        helper.defaultContact((List<Account>)Trigger.new);
    }
}