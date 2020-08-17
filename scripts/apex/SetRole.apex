/// Set the Role for the Running User
User me = new User(Id=UserInfo.getUserId());
UserRole ceo = [select id, name 
                  From UserRole 
                 Where Name='CEO'];

//
User myClone = me.clone();
myClone.username = myClone.username + '2';
myClone.alias = myClone.alias+'2';
myClone.nickname = myClone.nickname+'2';
myClone.UserRoleId = ceo.id;
insert myClone;