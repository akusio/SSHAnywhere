#import <Foundation/Foundation.h>

#import "SSHConnection.h"

%ctor{
    
    SSHConnection* ssh = [[SSHConnection alloc] initWithHost:@"127.0.0.1" port:2222 username:@"mobile" password:@"alpine"];
    
    if([ssh connect]){
        
        NSString* result = [ssh executeCommand:@"ls -l"];
        if(result){
            
            NSLog(@"SSHLOG: SUCCESS result : %@", result);
            
        }
        
        [ssh disconnect];
        
    }
    
}
