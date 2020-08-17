/**
* Self-Registration Handler used which demonstrates how to use PersonAccounts
* Best suited for B2C Customer Communities
**/ 

global WITHOUT SHARING class PAAuthHandler  implements Auth.RegistrationHandler{
    
    // For communities context, this optional custom attribute must be set
    public static final String NETWORK_ATTR='sfdc_networkid';
    
    // For this example, the Profile is hardwired
    public static final String COMMUNITY_PROFILE = 'Customer Community Login User';
    // To avoid hard coding a RecordType Id, we're going to select a valid one using SOQL
    private static final RecordType paRecordTypeInstance = [Select Id, Name, DeveloperName, IsPersonType 
                                                            From RecordType 
                                                            Where SObjectType='Account' 
                                                            and IsPersonType=TRUE limit 1];
    public static final String PA_RECORDTYPEID = paRecordTypeInstance.Id;
    public static final String ORG_UNIQUE_SUFFIX = '.mycommunity';
    
    /**
* Part of the AuthHandler interface.   Here you can examine the data passed in and decide if you have
* the minimum required information to create a user record.
* 
* This implementation simply always returns true and displays some debug detail in the logs.
**/ 
    global boolean canCreateUser(Auth.UserData data) {
        
        System.debug(data);
        for (String key : data.attributeMap.keySet()) {
            System.debug('Attribute: ' + key + ' : ' + data.attributeMap.get(key));
        }
        return data.email != null; // We're going to require an email address to be present!
    }
    
    /**
* CreateUser is part of the AuthHandler interface and must be implemented.
* 
* In this implementation, we're doing the heavy lifting to handle the two main use cases:
* >> Community User = We'll always create a PersonAccount which will be linked to the User
* >> Internal User = All we need to do here is create the User record
* 
* The Interface seperates the User creation from creation of non-User objects to avoid Mixed DML exceptions.
**/ 
    global User createUser(Id portalId, Auth.UserData data){
        if(!canCreateUser(data)) {
            //Returning null or throwing an exception fails the SSO flow
            return null;
        }
        
        User u = new User();
        
        if(isCommunityContext(data)) {
            // This example hardwires a specific profile
            Profile p = [SELECT Id FROM profile WHERE name= :COMMUNITY_PROFILE];           
            u.profileId = p.Id;
            u.contactId = findOrCreateContact(data).Id; // Community User must be linked to a Contact!
        } else {
            // Internal Contact -- example hardwires an internal profile
            Profile p = [SELECT Id FROM profile WHERE name='Standard User'];
            u.ProfileId = p.Id;
        }
        
        // Set the common properties
        u = mapUserProperties(u,data);            
        // These properties are only set on creation
        String alias = data.username == null ? data.email : data.username;
        //Alias must be 8 characters or less
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = UserInfo.getLocale();
        u.localesidkey = UserInfo.getLocale();
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = 'America/Los_Angeles';
        System.debug('createUser result:' + u);
        return u;
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        // Update the existing User for only the mapped properties
        final User u = new User(id=userId);
        update mapUserProperties(u,data);
        System.debug('updateUser:' + u);
    }
    
    /**
* Set or update the common properties from the external Provider
**/ 
    public static User mapUserProperties(User u, final Auth.UserData data) {
        u.email = data.email;
        u.Username = data.email + ORG_UNIQUE_SUFFIX;
        u.lastName = data.lastName;
        u.firstName = data.firstName;
        return u; 
    }
    
    /**
* Determine if this is CommunityContext or Internal.
* Return true if Community
**/ 
    public static Boolean isCommunityContext(final Auth.UserData data) {
        final Boolean result = data.attributeMap.containsKey(NETWORK_ATTR);
        System.debug('isCommunityContext? ' + result);
        return result;
    }
    
    /**
* Helper method to find and reuse existing PersonAccount record or create one
**/ 
    @testVisible
    private static Contact findOrCreateContact(final Auth.UserData data) {
        
        // Trivialized example of searching for the existing Contact
        final List<Contact> existingContacts = [SELECT Id, AccountId, Name, Email 
                                                From Contact 
                                                Where Email=:data.email
                                                and LastName = :data.lastName
                                                and FirstName = :data.firstName
                                                LIMIT 1];
        
        Contact result=null;
        if (existingContacts.isEmpty()) {
            // If not found, create a PersonAccount
            Account pa = new Account(RecordTypeId=PA_RECORDTYPEID);
            pa.PersonEmail = data.email;
            pa.firstName = data.firstName;
            pa.lastName = data.lastName;
            insert(pa);
            
            // Reselect to ensure that PersonContactId is populated!
            pa = [SELECT Id, PersonContactId FROM Account WHERE Id=:pa.id]; 
            
            System.debug(pa);            
            // To avoid an unnecessary query, just return the Id of the Contact Side
            result = new Contact(Id=pa.PersonContactId,AccountId=pa.Id);
        } else {
            result = existingContacts[0]; // Return the first hit
        }
        System.debug('Community Contact:' + result);
        return result;
    }
}