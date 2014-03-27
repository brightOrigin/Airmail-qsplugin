//
//  QSAirmailMediator.m
//  Airmail
//
//  Created by Tony Papale on 3/26/14.
//  Copyright (c) 2014 Bright Origin. All rights reserved.
//

#import "QSAirmailMediator.h"

@implementation QSAirmailMediator

#pragma mark Mail Mediator Protocol


- (NSDictionary *)smtpServerDetails
{
    // no Send Directly support for now :(
    return nil;

    /*
    NSString *smtpPath = [@"~/Library/Application Support/MailMate/Submission.plist" stringByStandardizingPath];
    NSDictionary *submission = [NSDictionary dictionaryWithContentsOfFile:smtpPath];
    NSArray *servers = submission[@"smtpServers"];
    if ([servers count]) {
        // use the fisrt one found
        NSDictionary *smtp = servers[0];
        NSURL *serverURL = [NSURL URLWithString:smtp[@"serverURL"]];
        NSString *server = [serverURL host];
        NSString *username = [serverURL user];
        NSString *password = @"";
        NSString *authenticate = @"NO";
        NSString *useTLS = @"NO";
        if ([username length]) {
            // use authentication and TLS
            useTLS = authenticate = @"YES";
            // get password from keychain
			UInt32 passLen = 0;
			void *rawPassword = nil;
			OSStatus status = SecKeychainFindInternetPassword(NULL, (UInt32)[server length], [server UTF8String], 0, NULL, (UInt32)[username length], [username UTF8String], 0, NULL, 0, kSecProtocolTypeSMTP, kSecAuthenticationTypeDefault, &passLen, &rawPassword, NULL);
			if (status == noErr) {
				password = [NSString stringWithCString:rawPassword encoding:[NSString defaultCStringEncoding]];
				SecKeychainItemFreeContent(NULL, rawPassword);
                if ([password length] > passLen) {
                    // trim extra characters from the buffer
                    password = [password substringToIndex:passLen];
                }
			}
        }
        return @{
                 QSMailMediatorServer: server,
                 QSMailMediatorPort: smtp[@"port"],
                 QSMailMediatorTLS: useTLS,
                 QSMailMediatorAuthenticate: authenticate,
                 QSMailMediatorUsername: username,
                 QSMailMediatorPassword: password,
                 };
    } else {
        // no SMTP servers defined
        return nil;
    }
     */
}


- (void)sendEmailTo:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow
{
    // remove all but the sender's e-mail address
    sender = [self addressOnly:sender];

    NSMutableString *scriptSource = [NSMutableString stringWithFormat:@"tell application \"Airmail\"\nactivate\nset theMessage to make new outgoing message with properties {subject:\"%@\", content:\"%@\"}\ntell theMessage\nset sender to \"%@\"\n", subject, body, sender];

    for (NSString *recipient in addresses)
    {
        [scriptSource appendString:[NSString stringWithFormat:@"make new to recipient at end of to recipients with properties {name:\"\", address:\"%@\"}\n", recipient]];
    }

    for (NSString *attachment in pathArray)
    {
        NSString* path = (NSString*)CFBridgingRelease(CFURLCopyFileSystemPath((__bridge CFURLRef)[NSURL fileURLWithPath:attachment], kCFURLHFSPathStyle));
        [scriptSource appendString:[NSString stringWithFormat:@"make new mail attachment with properties {filename:\"%@\" as alias}\n", path]];
    }

    if (sendNow)
    {
        [scriptSource appendString:@"sendmessage\n"];
    }
    else
    {
        [scriptSource appendString:@"compose\n"];
    }

    [scriptSource appendString:@"end tell\nend tell"];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *error = nil;
    [script executeAndReturnError:&error];
    if (error) {
        NSLog(@"Error sending message with Airmail: %@", error[NSAppleScriptErrorMessage]);
    }
}

- (NSImage *)iconForAction:(NSString *)actionID
{
    return [QSResourceManager imageNamed:@"Airmail"];
}

#pragma mark Helpers

- (NSString *)addressOnly:(NSString *)emailIdentity
{
    NSArray *parts = [emailIdentity componentsSeparatedByString:@">"];
    NSString *result = parts[0];
    parts = [result componentsSeparatedByString:@"<"];
    if ([parts count] > 1) {
        result = parts[1];
    }
    return result;
}

@end
