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

/*
- (NSDictionary *)smtpServerDetails
{
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
}
*/

- (void)sendEmailTo:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow
{
    // combine recipients into a string
    NSString *recipients = [addresses componentsJoinedByString:@","];
    // remove all but the sender's e-mail address
    sender = [self addressOnly:sender];
    NSString *mailtoURL = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@&from=%@", recipients, [subject URLEncoding], [body URLEncoding], sender];
    NSURL *attachmentURL = nil;
    NSString *attachmentString = nil;
    for (NSString *attachmentPath in pathArray) {
        attachmentURL = [NSURL fileURLWithPath:attachmentPath];
        attachmentString = [NSString stringWithFormat:@"&attachment-url=%@", [attachmentURL absoluteString]];
        mailtoURL = [mailtoURL stringByAppendingString:attachmentString];
    }
    if (sendNow) {
        mailtoURL = [mailtoURL stringByAppendingString:@"&send-now=yes"];
    }
    
    // "from" and "attachment-url" require the AppleScript specific trust option
    NSString *scriptSource = [NSString stringWithFormat:@"tell application \"Airmail\"\nopen location \"%@\" with trust\nactivate\nend tell", mailtoURL];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
    NSDictionary *error = nil;
    [script executeAndReturnError:&error];
    if (error) {
        NSLog(@"Error sending message with Airmail: %@", error[NSAppleScriptErrorMessage]);
    }
    [script release];
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
