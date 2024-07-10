#import <Foundation/Foundation.h>

@interface SSHConnection: NSObject
- (instancetype)initWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password;
- (BOOL)connect;
- (NSString *)executeCommand:(NSString *)command;
- (void)disconnect;
@end
