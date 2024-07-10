#import <Foundation/Foundation.h>
#include "libssh2.h"
#include "libssh2_sftp.h"
#include <stdlib.h>
#include <errno.h>
#include <netinet/in.h>
#include <netdb.h>
#include <sys/socket.h>
#include <unistd.h>

#import "SSHConnection.h"

@implementation SSHConnection {
    NSString *_host;
    int _port;
    NSString *_username;
    NSString *_password;
    int _sock;
    LIBSSH2_SESSION *_session;
}

- (instancetype)initWithHost:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        _host = host;
        _port = port;
        _username = username;
        _password = password;
    }
    return self;
}

- (BOOL)connect {
    struct sockaddr_in sin;
    struct hostent *hp;
    
    hp = gethostbyname([_host UTF8String]);
    if (!hp) {
        NSLog(@"Error: Unknown host.");
        return NO;
    }
    
    _sock = socket(AF_INET, SOCK_STREAM, 0);
    if (_sock < 0) {
        NSLog(@"Error: Unable to create socket.");
        return NO;
    }
    
    sin.sin_family = AF_INET;
    sin.sin_port = htons(_port);
    sin.sin_addr = *((struct in_addr *)hp->h_addr);
    
    if (connect(_sock, (struct sockaddr*)(&sin), sizeof(struct sockaddr_in)) != 0) {
        NSLog(@"Error: Unable to connect to %@:%d", _host, _port);
        return NO;
    }
    
    libssh2_init(0);
    
    _session = libssh2_session_init();
    if (!_session) {
        NSLog(@"Error: Unable to initialize SSH session.");
        close(_sock);
        return NO;
    }
    
    if (libssh2_session_handshake(_session, _sock)) {
        NSLog(@"Error: Failure establishing SSH session.");
        libssh2_session_free(_session);
        close(_sock);
        return NO;
    }
    
    if (libssh2_userauth_password(_session, [_username UTF8String], [_password UTF8String])) {
        NSLog(@"Error: Authentication by password failed.");
        libssh2_session_disconnect(_session, "Normal Shutdown, Thank you for playing");
        libssh2_session_free(_session);
        close(_sock);
        return NO;
    }
    
    return YES;
}

- (NSString *)executeCommand:(NSString *)command {
    LIBSSH2_CHANNEL *channel = libssh2_channel_open_session(_session);
    if (!channel) {
        NSLog(@"Error: Unable to open channel.");
        return nil;
    }
    
    if (libssh2_channel_exec(channel, [command UTF8String])) {
        NSLog(@"Error: Unable to execute command.");
        libssh2_channel_free(channel);
        return nil;
    }
    
    NSMutableString *response = [NSMutableString string];
    char buffer[0x4000];
    ssize_t n = 0;
    
    while ((n = libssh2_channel_read(channel, buffer, sizeof(buffer))) > 0) {
        [response appendString:[[NSString alloc] initWithBytes:buffer length:n encoding:NSUTF8StringEncoding]];
    }
    
    if (n < 0) {
        NSLog(@"Error: Failed reading command response.");
        libssh2_channel_free(channel);
        return nil;
    }
    
    libssh2_channel_close(channel);
    libssh2_channel_free(channel);

    return response;
}

- (void)disconnect {
    if (_session) {
        libssh2_session_disconnect(_session, "Normal Shutdown, Thank you for playing");
        libssh2_session_free(_session);
    }
    if (_sock) {
        close(_sock);
    }
    libssh2_exit();
}

@end
