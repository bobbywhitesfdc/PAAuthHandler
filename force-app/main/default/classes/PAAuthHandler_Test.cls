@isTest(isParallel=true)
public class PAAuthHandler_Test {
    public static final String NETWORKID = '0DB1100000023c9'; //NOSONAR
    private static testmethod void testCanCreateUser() {
        System.Assert(new PAAuthHandler().canCreateUser(getMockUserData()));
    }
    private static testmethod void testCreateUserCommunity() {
        final Auth.UserData mockUserData = getMockUserData();
        User result = new PAAuthHandler().createUser(NETWORKID, mockUserData);
        System.Assert(result!=null,'No user record!');
        System.Assert(result.UserName!=null,'Username is null');
        System.Assert(result.ContactId!=null,'Community User must have a valid Contact!');
        System.AssertEquals(result.FirstName,mockUserData.FirstName,'First name does not match');
        System.AssertEquals(result.LastName,mockUserData.LastName,'Last name does not match');
        System.AssertEquals(result.Email,mockUserData.Email,'Email address does not match');       
    }

    
    /**
* Helper method to construct test data
**/ 
    private static Auth.UserData getMockUserData() {
        final Map<String,String> customAttrs = new Map<String,String>();
        customAttrs.put(PAAuthHandler.NETWORK_ATTR,NETWORKID);
        return new Auth.UserData('user1'
                                 , 'Chevy'
                                 ,'Chase'
                                 , 'Chevy Chase'
                                 , 'chevy@caddyshack.com'
                                 , '/someUrl'
                                 , 'user1'
                                 , 'en_US'
                                 , 'LinkedIn'
                                 , 'https://www.linkedin.com/oauth'
                                 , customAttrs);
    }
}