//
//  WhatsAppAPI.m
//  WhatsApp Legacy
//
//  Created by Gian Luca Russo on 28/07/24.
//  Copyright (c) 2024 Gian Luca Russo. All rights reserved.
//

#import "WhatsAppAPI.h"
#import "JSONUtility.h"
#import "AppDelegate.h"
#import "CocoaFetch.h"
#import "ChatsViewController.h"

@implementation WhatsAppAPI

NSString * const WSPContactType_toString[] = {
    [REGULARUSER] = @"Personal User",
    [BUSINESSUSER] = @"Business User",
    [ENTERPRISEUSER] = @"Enterprise User",
    [YOUUSER] = @"You"
};

NSString * const WSPInfoType_toString[] = {
    [DEFAULT] = @"Hey, I'm using WhatsApp",
    [AVAILABLE] = @"Available",
    [BUSY] = @"Busy",
    [INSCHOOL] = @"In school",
    [INCINEMA] = @"At the Cinema",
    [INWORK] = @"At Work",
    [INGYM] = @"At the Gym",
    [INREUNION] = @"In a Reunion",
    [LOWBATTERY] = @"Low Battery",
    [ONLYWSP] = @"I can't talk, only WhatsApp",
    [ONLYEMERGENCY] = @"Only Emergency Calls",
    [SLEEPING] = @"Sleeping"
};

NSString * const WSPMsgMediaType_toString[] = {
    [STICKER] = @"Sticker",
    [PICTURE] = @"Picture",
    [VIDEO] = @"Video",
    [PTT] = @"Voice Note",
    [AUDIO] = @"Audio",
    [REVOKED] = @"Revoked",
    [LOCATION] = @"Location",
    [UNKNOWN] = @"Unknown"
};

+ (NSDictionary *)getChatList {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *chats;
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        chats = [CocoaFetch fetchJSON:[NSString stringWithFormat:@"%@/getChats", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]] withMethod:@"GET"];
        [CocoaFetch saveDictionaryToJSON:chats withFileName:@"chatList"];
        return chats;
    } else {
        return [CocoaFetch loadDictionaryFromJSONWithFileName:@"chatList"];
    }
}

+ (void)getChatListAsync {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/getChats", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]] withMethod:@"GET" delegate:appDelegate.chatsViewController];
    }
}

+ (void)getBroadcastListAsync {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/getBroadcasts", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]] withMethod:@"GET" delegate:appDelegate.newsViewController];
    }
}

+ (NSDictionary *)getContactList {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *contacts;
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        contacts = [CocoaFetch fetchJSON:[NSString stringWithFormat:@"%@/getContacts", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]] withMethod:@"GET"];
        [CocoaFetch saveDictionaryToJSON:contacts withFileName:@"contactList"];
        return contacts;
    } else {
        return [CocoaFetch loadDictionaryFromJSONWithFileName:@"contactList"];
    }
}

+ (void)getContactListAsync {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/getContacts", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]] withMethod:@"GET" delegate:appDelegate.contactsViewController];
    }
}

+ (void)downloadAndProcessImage:(NSString *)contactNumber {
    NSString *safeContactNumber = [contactNumber copy];
    
    // Generar la URL de la imagen
    NSString *imgURL = [NSString stringWithFormat:@"%@/getAvatarImg/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"], safeContactNumber];;
    
    // Descargar la imagen
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgURL]];
    UIImage *profImg = [UIImage imageWithData:imageData];
    if (!profImg) {
        NSLog(@"Failed to convert data to UIImage");
        return;
    }

    NSData *pngData = UIImagePNGRepresentation(profImg);
    if (!pngData) {
        NSLog(@"Failed to convert UIImage to PNG data");
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:pngData forKey:[NSString stringWithFormat:@"%@-largeprofile", safeContactNumber]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary *)getContactInfo:(NSString *)contactNumber {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    for (NSDictionary *contact in appDelegate.contactsViewController.contactList) {
        id number = contact[@"number"];
        if ([number isKindOfClass:[NSString class]] && [number length] > 0 && [number isEqualToString:contactNumber]) {
            return contact;
        }
    }
    return nil;
}

+ (NSDictionary *)getChatInfo:(NSString *)contactNumber {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    for(NSDictionary *chat in appDelegate.chatsViewController.chatList){
        if ([[[chat objectForKey:@"id"] objectForKey:@"_serialized"] isEqualToString:contactNumber]) {
            return chat;
        }
    }
    return nil;
}

+ (void)fetchMessagesfromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup light:(BOOL)light {
    [self sendSeenfromNumber:contactNumber isGroup:isGroup];
    NSLog(@"Sent seen");
    NSDictionary *messages;
    if (isGroup == true){
        messages = [CocoaFetch fetchJSON:[NSString stringWithFormat:@"%@/getChatMessages/%@?isGroup=1&isLight=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, light] withMethod:@"GET"];
    } else {
        messages = [CocoaFetch fetchJSON:[NSString stringWithFormat:@"%@/getChatMessages/%@?isLight=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, light] withMethod:@"GET"];
    }
    //[CocoaFetch saveDictionaryToJSON:messages withFileName:[NSString stringWithFormat:@"%@-chatMessages", contactNumber]];
}

+ (void)fetchMessagesfromNumberAsync:(NSString *)contactNumber isGroup:(BOOL)isGroup light:(BOOL)light {

    [self sendSeenfromNumber:contactNumber isGroup:isGroup];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/getChatMessages/%@?isGroup=%i&isLight=0", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, (isGroup == true ? 1 : 0)] withMethod:@"GET" delegate:(light == YES ? nil: appDelegate.chatViewController)];
    }
}

+ (void)fetchMessagesfromNumberAsyncFirstTime:(NSString *)contactNumber isGroup:(BOOL)isGroup light:(BOOL)light delegate:(id)delegate {
    NSLog(@"Delegate: %@", delegate);

    [self sendSeenfromNumber:contactNumber isGroup:isGroup];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        id retainedDelegate = [delegate retain]; // retain the delegate
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/getChatMessages/%@?isGroup=%i&isLight=0", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"], contactNumber, (isGroup ? 1 : 0)] withMethod:@"GET" delegate:retainedDelegate];
    }
}

+ (void)setTypingStatusfromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup isVoiceNote:(BOOL)isVoiceNote {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/setTypingStatus/%@?isGroup=%i&isVoiceNote=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, (isGroup == true ? 1 : 0), isVoiceNote] withMethod:@"POST" delegate:nil];
    }
}

+ (void)clearStatefromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/clearState/%@?isGroup=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, (isGroup == true ? 1 : 0)] withMethod:@"POST" delegate:nil];
    }
}

+ (void)sendMessageFromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup bodyMsg:(NSDictionary *)bodyMsg
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/sendMessage/%@?isGroup=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, (isGroup == true ? 1 : 0)] withMethod:@"POST" jsonBody:bodyMsg delegate:nil];
    }
}

+ (void)setStatusMsg:(NSString *)statusMsg
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/setStatusInfo/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],statusMsg] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
    }
}

+ (void)setMutefromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup muteState:(NSInteger)muteState
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/setMute/%@/%i?isGroup=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, muteState, (isGroup == true ? 1 : 0)] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
    }
}

+ (void)setBlockfromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/setBlock/%@?isGroup=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, (isGroup == true ? 1 : 0)] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
    }
}

+ (void)sendSeenfromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/readChat/%@?isGroup=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, (isGroup == true ? 1 : 0)] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
    }
}

+ (void)deleteMessageFromId:(NSString *)messageId everyone:(int)everyone
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/deleteMessage/%@/%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],messageId, everyone] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
    }
}

+ (void)sendSeenfromBroadcast:(NSString *)message
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/seenBroadcast/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],message] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
    }
}

+ (void)deleteChatfromNumber:(NSString *)contactNumber isGroup:(BOOL)isGroup
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/deleteChat/%@?isGroup=%i", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber, (isGroup == true ? 1 : 0)] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
        [CocoaFetch deleteJSONWithFileName:[NSString stringWithFormat:@"%@-chatMessages", contactNumber]];
    }
}

+ (void)leaveGroupfromNumber:(NSString *)contactNumber
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        [JSONFetcher fetchJSON:[NSString stringWithFormat:@"%@/leaveGroup/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"],contactNumber] withMethod:@"POST" delegate:appDelegate.myStatusViewController];
    }
}

+ (NSDictionary *)getMessagesfromNumber:(NSString *)contactNumber {
    return [CocoaFetch loadDictionaryFromJSONWithFileName:[NSString stringWithFormat:@"%@-chatMessages", contactNumber]];
}

+ (NSDictionary *)getMyContact {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    for(NSDictionary *contact in appDelegate.contactsViewController.contactList){
        if ([[contact objectForKey:@"isMe"] boolValue] == true) {
            return contact;
        }
    }
    return nil;
}

+ (NSDictionary *)getGroupInfo:(NSString *)groupNumber {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    for(NSDictionary *group in appDelegate.chatsViewController.groupList){
        if ([[[group objectForKey:@"id"] objectForKey:@"_serialized"] isEqualToString:groupNumber]) {
            return group;
        }
    }
    return nil;
}

@end
