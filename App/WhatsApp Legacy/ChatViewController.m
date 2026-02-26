//
//  ChatViewController.m
//
//  Created by Jesse Squires on 2/12/13.
//  Copyright (c) 2013 Hexed Bits. All rights reserved.
//
//  http://www.hexedbits.com
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
//  associated documentation files (the "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
//  following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
//  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
//  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "AppDelegate.h"
#import "ChatViewController.h"
#import "ContactsViewController.h"
#import "ProfileViewController.h"
#import "WhatsAppAPI.h"
#import "CocoaFetch.h"
#import "UnknownMessage.h"
#import "VoiceNoteMessage.h"
#import "PictureMessage.h"
#import "DeletedMessage.h"
#import "LocationMessage.h"
#import "StickerMessage.h"
#import "VideoMessage.h"
#import "NSData+Base64.h"
#import "LocationViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

#define IS_IOS4orHIGHER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0)

@interface ChatViewController ()
@property (retain) AppDelegate *appDelegate;
@property (assign) NSInteger hiddenMessages;
@property (nonatomic, assign) CGPoint savedContentOffset;
@property (assign) BOOL loaded;
@end

@implementation ChatViewController
@synthesize appDelegate, levelNav, chatContacts, chatMessages, profileButton, smallImage, largeImage, contactNumber, timestamp, hiddenMessages, savedContentOffset, loaded, nameLabel, statusLabel, titleView, imagePicker;

#pragma mark - Initialization
- (UIButton *)sendButton
{
    // Override to use a custom send button
    // The button's frame is set automatically for you
    return [UIButton defaultSendButton];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [WhatsAppAPI sendSeenfromNumber:self.contactNumber isGroup:self.isGroup];
    [super viewDidLoad];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.delegate = self;
    self.dataSource = self;
    self.inputToolBarView.textView.delegate = self;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    levelNav = 1;
    loaded = true;

    [self reloadChat];
    
    self.savedContentOffset = CGPointZero;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.savedContentOffset = self.tableView.contentOffset;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (![self.navigationController.viewControllers containsObject:self]) {
        loaded = false;
        [self.attachToolBarView setHidden:YES];
        for (UIView *view in [self.tableView subviews]) {
            if ([view isKindOfClass:[UITableViewCell class]]) {
                [view removeFromSuperview];
                view = nil;
            }
        }
        self.contactNumber = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!CGPointEqualToPoint(self.savedContentOffset, CGPointZero) && loaded == TRUE) {
        [self.tableView setContentOffset:self.savedContentOffset animated:NO];
    }
    
    if (!loaded) {
        [self reloadChat];
        levelNav = 1;
        self.hiddenMessages = 0;
        [self.tableView reloadData];
        loaded = TRUE;
        [self scrollToBottomAnimated:NO];
        self.savedContentOffset = CGPointZero;
    }
}

- (void)loadStatusText:(BOOL)fromContact withDic:(NSDictionary *)dic andStatus:(NSString *)statusText {
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, (fromContact == YES ? 190 : 208), 44)];
    self.titleView.backgroundColor = [UIColor clearColor];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, (fromContact == YES ? 190 : 208), 24)];
    self.nameLabel.text = self.title;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:(fromContact == YES ? 18 : 19)];
    self.nameLabel.textAlignment = UITextAlignmentCenter;
    self.nameLabel.backgroundColor = [UIColor clearColor];
    // Configura la fuente y el tamaño del texto según sea necesario
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, (fromContact == YES ? 190 : 208), 20)];
    self.statusLabel.textAlignment = UITextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:13];
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.statusLabel.shadowOffset = CGSizeMake(0, -1); // Desplazamiento de la sombra
    
    self.nameLabel.textColor = [UIColor blackColor];
    self.statusLabel.textColor = [UIColor darkGrayColor];

    if (self.isGroup == false){
        BOOL isBusiness = [[appDelegate.activeProfileView objectForKey:@"isBusiness"] boolValue];
        BOOL isEnterprise = [[appDelegate.activeProfileView objectForKey:@"isEnterprise"] boolValue];
        if([statusText isEqualToString:@"TYPING"]){
            self.statusLabel.text = @"Typing...";
        } else if([statusText isEqualToString:@"RECORDING_AUDIO"]){
            self.statusLabel.text = @"Recording...";
        } else {
            if(isBusiness == false && isEnterprise == false){
                self.statusLabel.text = WSPContactType_toString[REGULARUSER];
            }
            if(isBusiness == true && isEnterprise == false){
                self.statusLabel.text = WSPContactType_toString[BUSINESSUSER];
            }
            if(isEnterprise == true){
                self.statusLabel.text = WSPContactType_toString[ENTERPRISEUSER];
            }
        }
    } else {
        NSMutableArray *participantsNames = [[NSMutableArray alloc] init];
        NSArray *participantsContacts = [[appDelegate.activeProfileView objectForKey:@"groupMetadata"] objectForKey:@"participants"];
        //NSLog(@"Hello: %@", appDelegate.activeProfileView);
        for(NSDictionary *participantContact in participantsContacts){
            for(NSDictionary *contact in appDelegate.contactsViewController.contactList){
                id contactNumber = contact[@"number"];
                NSDictionary *participantIdDict = participantContact[@"id"];
                NSString *participantUser = nil;

                if ([participantIdDict isKindOfClass:[NSDictionary class]]) {
                    participantUser = participantIdDict[@"user"];
                }

                if ([contactNumber isKindOfClass:[NSString class]] &&
                    [participantUser isKindOfClass:[NSString class]] &&
                    [contactNumber isEqualToString:participantUser]) {

                    NSString *myNumber = appDelegate.contactsViewController.myContact[@"number"];

                    if ([myNumber isKindOfClass:[NSString class]] &&
                        [contactNumber isEqualToString:myNumber]) {

                        [participantsNames addObject:WSPContactType_toString[YOUUSER]];
                    } else {
                        NSNumber *isMyContact = contact[@"isMyContact"];
                        NSString *shortName = [contact[@"shortName"] isKindOfClass:[NSString class]] ? contact[@"shortName"] : nil;
                        NSString *pushName = [contact[@"pushname"] isKindOfClass:[NSString class]] ? contact[@"pushname"] : nil;
                        NSString *rawNumber = [contact[@"number"] isKindOfClass:[NSString class]] ? contact[@"number"] : nil;

                        NSString *finalName = nil;

                        if ([isMyContact respondsToSelector:@selector(boolValue)] &&
                            [isMyContact boolValue] &&
                            shortName.length > 0) {

                            finalName = shortName;
                        } else if (pushName.length > 0) {
                            finalName = pushName;
                        } else if (rawNumber.length > 0) {
                            finalName = rawNumber;
                        } else {
                            finalName = @"Unknown";
                        }

                        [participantsNames addObject:finalName];
                    }
                }
            }
        }
        self.statusLabel.text = [participantsNames componentsJoinedByString:@", "];
    }
    
    [self.titleView addSubview:self.nameLabel];
    [self.titleView addSubview:self.statusLabel];
    self.navigationItem.titleView = self.titleView;
}

- (void)profileButtonTapped {
    if(self.isGroup == true){
        appDelegate.activeProfileView = [WhatsAppAPI getGroupInfo:self.contactNumber];
    } else {
        appDelegate.activeProfileView = [WhatsAppAPI getContactInfo:self.contactNumber];
    }
    [self performSelectorOnMainThread:@selector(updateProfileView) withObject:nil waitUntilDone:NO];
}

- (void)updateProfileView {
    ProfileViewController *profileViewController = [[ProfileViewController alloc] init];
    profileViewController.title = self.title;
    profileViewController.contactNumber = self.contactNumber;
    profileViewController.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:profileViewController animated:YES];
    profileViewController.profileImg.image = self.largeImage;
    [profileViewController release];
}

- (void)reloadChat {
    
    self.chatMessages = [[WhatsAppAPI getMessagesfromNumber:self.contactNumber] objectForKey:@"chatMessages"];
    
    if(appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        NSLog(@"Fetching messages from number async");
        [WhatsAppAPI fetchMessagesfromNumberAsync:self.contactNumber isGroup:self.isGroup light:false];
    }
}

- (void)fetcherDidFinishWithJSON:(NSArray *)json error:(NSError *)error {
    if (json) {
        self.chatMessages = [json mutableCopy];

        [self.tableView reloadData];
        [self scrollToBottomAnimated:YES];

        NSDictionary *dict = @{@"chatMessages": self.chatMessages};
        //[CocoaFetch saveDictionaryToJSON:dict withFileName:[NSString stringWithFormat:@"%@-chatMessages", self.contactNumber]];
    }

    [WhatsAppAPI sendSeenfromNumber:self.contactNumber isGroup:self.isGroup];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView.contentOffset.y == 0 && self.hiddenMessages > 0 && loaded == true){
        levelNav++;
        UIScrollView *scrollView = self.tableView;
        float oldScrollContentSizeHeight = scrollView.contentSize.height;
        [self.tableView reloadData];
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x,scrollView.contentSize.height - oldScrollContentSizeHeight);
        
        // Create a transition animation
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.5];
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, scrollView.contentSize.height - oldScrollContentSizeHeight - 100);
        [UIView commitAnimations];
    } else if (scrollView.contentOffset.y == 0) {
        [self reloadChat];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self freeResourcesForNonVisibleCells];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self freeResourcesForNonVisibleCells];
}

- (void)freeResourcesForNonVisibleCells {
    NSArray *visibleCells = [self.tableView visibleCells];
    NSArray *subviews = [self.tableView subviews];
    
    for (UIView *view in subviews) {
        if ([view isKindOfClass:[UITableViewCell class]] && ![visibleCells containsObject:view]) {
            [view removeFromSuperview];
            view = nil;
        }
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.chatMessages.count <= (levelNav * 100)){
        return self.chatMessages.count;
    } else {
        self.hiddenMessages = self.chatMessages.count - (levelNav * 100);
        if(self.hiddenMessages >= 100){
            return (levelNav * 100);
        } else {
            self.hiddenMessages = 0;
            return self.chatMessages.count;
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *data = UIImageJPEGRepresentation(image, 0.8);
        NSString *base64String = [data base64EncodedString];
        [WhatsAppAPI sendMessageFromNumber:self.contactNumber isGroup:self.isGroup bodyMsg:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            base64String, @"mediaBase64",
                                                                                            @"true", @"sendAsPhoto",
                                                                                            [CocoaFetch contentTypeForImageData:data], @"mimeType",
                                                                                            nil]];
        [JSMessageSoundEffect playMessageSentSound];
        [WhatsAppAPI fetchMessagesfromNumberAsync:self.contactNumber isGroup:self.isGroup light:NO];
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSLog(@"Video recorded");
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // Discard the picker when the user cancels
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    NSMutableDictionary* msgToSend = [[NSMutableDictionary alloc] init];
    [msgToSend setValue:text forKey:@"messageText"];
    if (self.attachToolBarView.hidden == NO){
        [msgToSend setValue:self.attachToolBarView.bubbleReply.msgId forKey:@"replyTo"];
        self.attachToolBarView.hidden = YES;
    }
    [WhatsAppAPI sendMessageFromNumber:self.contactNumber isGroup:self.isGroup bodyMsg:msgToSend];
    [JSMessageSoundEffect playMessageSentSound];
    [WhatsAppAPI clearStatefromNumber:self.contactNumber isGroup:self.isGroup];
    [self finishSend];
    [WhatsAppAPI fetchMessagesfromNumberAsync:self.contactNumber isGroup:self.isGroup light:NO];
}

- (void)attachPressed:(UIButton *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Photos and Videos", @"Camera", @"Location", @"Sticker", nil];
    
    [actionSheet showInView:self.view];
    [actionSheet release];
}

- (void)finishSendVoiceNote
{
    NSData *fileData = [NSData dataWithContentsOfURL:appDelegate.voiceNoteManager.audioRecorder.url];
    if (fileData){
        NSString *base64String = [fileData base64EncodedString];
        [WhatsAppAPI sendMessageFromNumber:self.contactNumber isGroup:self.isGroup bodyMsg:[NSDictionary dictionaryWithObjectsAndKeys:
                base64String, @"mediaBase64",
                @"true", @"sendAsVoiceNote",
                nil]];
        [JSMessageSoundEffect playMessageSentSound];
        [WhatsAppAPI fetchMessagesfromNumberAsync:self.contactNumber isGroup:self.isGroup light:NO];
    }
}

-(void)voiceNoteStatus {
    [WhatsAppAPI setTypingStatusfromNumber:self.contactNumber isGroup:self.isGroup isVoiceNote:true];
}

-(void)voiceNoteClear {
    [WhatsAppAPI clearStatefromNumber:self.contactNumber isGroup:self.isGroup];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"fromMe"] boolValue] == true){
        return JSBubbleMessageTypeOutgoing;
    }
    return JSBubbleMessageTypeIncoming;
    //return (indexPath.row % 2) ? JSBubbleMessageTypeIncoming : JSBubbleMessageTypeOutgoing;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyCustom;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyBoth;
}

- (JSAvatarStyle)avatarStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*NSString *msgType = [[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"type"];
    if([msgType isEqualToString:@"ptt"]){
        return JSAvatarStyleSquare;
    }*/
    return JSAvatarStyleNone;
}


//  Optional delegate method
//  Required if using `JSMessagesViewTimestampPolicyCustom`
//
//  - (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
//

- (void)textViewDidChange:(UITextView *)textView {
    [super textViewDidChange:textView];
    [WhatsAppAPI setTypingStatusfromNumber:self.contactNumber isGroup:self.isGroup isVoiceNote:false];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            // Initialise UIImagePickerController
            self.imagePicker = [[UIImagePickerController alloc] init];
            self.imagePicker.delegate = self;
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.imagePicker.allowsEditing = NO;
            self.imagePicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
            
            // Present camera
            [self presentModalViewController:self.imagePicker animated:YES];
            break;
        case 1:
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                
                AVAuthorizationStatus cameraAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                AVAuthorizationStatus micAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];

                if (cameraAuthStatus == AVAuthorizationStatusDenied || micAuthStatus == AVAuthorizationStatusDenied) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Denied"
                                                                    message:@"Please enable camera and microphone access in Settings"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    return;
                }

                void (^presentCamera)(void) = ^{
                    self.imagePicker = [[UIImagePickerController alloc] init];
                    self.imagePicker.delegate = self;
                    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    self.imagePicker.allowsEditing = NO;

                    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
                    if ([availableMediaTypes containsObject:(NSString *)kUTTypeMovie]) {
                        self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
                        self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                        self.imagePicker.videoMaximumDuration = 60.0;
                    } else {
                        self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
                    }

                    [self presentModalViewController:self.imagePicker animated:YES];
                };

                if (cameraAuthStatus == AVAuthorizationStatusNotDetermined) {
                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                        if (granted) {
                            if (micAuthStatus == AVAuthorizationStatusNotDetermined) {
                                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL grantedAudio) {
                                    if (grantedAudio) dispatch_async(dispatch_get_main_queue(), presentCamera);
                                }];
                            } else if (micAuthStatus == AVAuthorizationStatusAuthorized) {
                                dispatch_async(dispatch_get_main_queue(), presentCamera);
                            }
                        }
                    }];
                } else if (micAuthStatus == AVAuthorizationStatusNotDetermined) {
                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL grantedAudio) {
                        if (grantedAudio) dispatch_async(dispatch_get_main_queue(), presentCamera);
                    }];
                } else {
                    presentCamera();
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"This device doesn't have a camera."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            break;
        case 2:
            if (IS_IOS4orHIGHER){
                LocationViewController *locationViewController = [[LocationViewController alloc] initWithNibName:@"LocationViewController" bundle:nil];
                [self presentModalViewController:locationViewController animated:YES];
            }
            break;
        case 3:
            
            break;
        default:
            break;
    }
}

#pragma mark - Messages view data source
- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *msgType = [[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"type"];
    if([msgType isEqualToString:@"location"]){
        return nil;
    }
    return [[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"body"];
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSTimeInterval timeint = [[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"timestamp"] doubleValue];
    NSDate *time = [NSDate dateWithTimeIntervalSince1970:timeint];
    return time;
}


-(BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row > 0){
        NSTimeInterval timeint = [[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"timestamp"] doubleValue];
        NSTimeInterval previoustimeint = [[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)-1] objectForKey:@"timestamp"] doubleValue];
        if([CocoaFetch isDifferentDayWithTimestamp:timeint previousTimestamp:previoustimeint]){
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

- (NSInteger *)ackForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (int *)[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"ack"] integerValue];
}

- (BOOL)showUserPolicyForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (self.isGroup == true && ([self.delegate messageTypeForRowAtIndexPath:indexPath] == JSBubbleMessageTypeIncoming));
}

- (NSString *)msgIdForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"id"] objectForKey:@"_serialized"];
}

- (NSString *)userNameForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *author = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"id"] objectForKey:@"participant"] objectForKey:@"user"];
    
    for(NSDictionary *contact in appDelegate.contactsViewController.contactList){
        NSString *contactNumber = contact[@"number"];
        NSNumber *isMyContact = contact[@"isMyContact"];
        
        if ([contactNumber isKindOfClass:[NSString class]] && [contactNumber isEqualToString:author]) {
            if([contactNumber isEqualToString:[appDelegate.contactsViewController.myContact objectForKey:@"number"]]){
                return WSPContactType_toString[YOUUSER];
            } else if([isMyContact respondsToSelector:@selector(boolValue)] && [isMyContact boolValue]){
                return contact[@"shortName"];
            } else {
                return contact[@"pushname"];
            }
        }
    }
    
    return @"Unknown";
}

- (BOOL)hasReplyForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"hasQuotedMsg"] boolValue];
}

- (NSString *)quotedTextForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *messageBody = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"quotedMsg"] objectForKey:@"body"];
    NSString *messageType = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"quotedMsg"] objectForKey:@"type"];
    
    if(messageBody == nil){
        return nil;
    }
    
    if([messageType isEqualToString:@"chat"]){
        return [NSString stringWithFormat:@"%@", messageBody];
    } else {
        if([messageType isEqualToString:@"ptt"]){
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[PTT]];
        } else if([messageType isEqualToString:@"audio"]){
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[AUDIO]];
        } else if([messageType isEqualToString:@"image"]) {
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[PICTURE]];
        } else if([messageType isEqualToString:@"sticker"]) {
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[STICKER]];
        } else if([messageType isEqualToString:@"video"]) {
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[VIDEO]];
        } else if([messageType isEqualToString:@"revoked"]) {
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[REVOKED]];
        } else if([messageType isEqualToString:@"location"]) {
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[LOCATION]];
        } else {
            return [NSString stringWithFormat:@"(%@)", WSPMsgMediaType_toString[UNKNOWN]];
        }
    }
}

- (NSString *)quotedUserNameForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* author = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"quotedParticipant"] objectForKey:@"user"];
    
    for(NSDictionary *contact in appDelegate.contactsViewController.contactList){
        NSDictionary *contactId = [contact[@"id"] isKindOfClass:[NSDictionary class]] ? contact[@"id"] : nil;
        NSString *contactUser = [contactId[@"user"] isKindOfClass:[NSString class]] ? contactId[@"user"] : nil;
        NSString *contactNumber = [contact[@"number"] isKindOfClass:[NSString class]] ? contact[@"number"] : nil;
        
        if (!(contactUser && [contactUser isEqualToString:author])) continue;

        NSString *myNumber = [appDelegate.contactsViewController.myContact[@"number"] isKindOfClass:[NSString class]]
                             ? appDelegate.contactsViewController.myContact[@"number"]
                             : nil;

        if (myNumber && contactNumber && [contactNumber isEqualToString:myNumber]) {
            return WSPContactType_toString[YOUUSER];
        }

        NSString *shortName = [contact[@"shortName"] isKindOfClass:[NSString class]] ? contact[@"shortName"] : nil;
        NSString *pushName = [contact[@"pushname"] isKindOfClass:[NSString class]] ? contact[@"pushname"] : nil;

        if (shortName.length > 0) {
            return shortName;
        } else if (pushName.length > 0) {
            return pushName;
        } else if (contactNumber.length > 0) {
            return [NSString stringWithFormat:@"+%@", contactNumber];
        }
    }
    
    return @"Unknown";
}

- (BOOL)hasMediaForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *msgType = [[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"type"];
    if([msgType isEqualToString:@"chat"]){
        return NO;
    }
    return YES;
}

- (UIView *)mediaViewForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *msgType = [[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"type"];
    if([msgType isEqualToString:@"ptt"] || [msgType isEqualToString:@"audio"]){
        VoiceNoteMessage *vnm = [[VoiceNoteMessage alloc] initWithId:[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"id"] objectForKey:@"_serialized"] withDuration:[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"duration"] integerValue] withViewController:self audioVoiceNote:[msgType isEqualToString:@"ptt"] audioPlayed:([[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"ack"] integerValue] == 4) andMsgType:[self.delegate messageTypeForRowAtIndexPath:indexPath]];
        if ([msgType isEqualToString:@"ptt"]){
            vnm.avatarImage = ([self.delegate messageTypeForRowAtIndexPath:indexPath] == JSBubbleMessageTypeIncoming ? [self.dataSource avatarImageForIncomingMessageForRowAtIndexPath:indexPath] : [self.dataSource avatarImageForOutgoingMessage]);
        }
        return vnm;
    }
    if([msgType isEqualToString:@"image"]){
        CGFloat width = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"width"] floatValue] ? : 220.0f;
        CGFloat height = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"height"] floatValue] ? : 220.0f;
        return [[PictureMessage alloc] initWithSize:CGSizeMake(width, height) withId:[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"id"] objectForKey:@"_serialized"] withFileSize:[[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"size"] intValue] andViewController:self];
    }
    if([msgType isEqualToString:@"sticker"]){
        return [[StickerMessage alloc] initWithId:[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"id"] objectForKey:@"_serialized"]];
    }
    if ([msgType isEqualToString:@"video"]){
        CGFloat width = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"width"] floatValue] ? : 220.0f;
        CGFloat height = [[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"height"] floatValue] ? : 220.0f;
        return [[VideoMessage alloc] initWithSize:CGSizeMake(width, height) withId:[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"id"] objectForKey:@"_serialized"] withDuration:[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"duration"] integerValue]];
    }
    if([msgType isEqualToString:@"revoked"]){
        return [[DeletedMessage alloc] init];
    }
    if([msgType isEqualToString:@"location"]){
        return [[LocationMessage alloc] initWithLatitude:[[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"lat"] floatValue] andLongitude:[[[[self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)] objectForKey:@"_data"] objectForKey:@"lng"] floatValue]];
    }
    return [[UnknownMessage alloc] initWithType:[self.delegate messageTypeForRowAtIndexPath:indexPath]];
}

- (void)downloadAndProcessImageContact:(NSString *)ocontactNumber {
    [WhatsAppAPI downloadAndProcessImage:ocontactNumber];
}

- (UIImage *)avatarImageForIncomingMessageForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isGroup) {
        NSDictionary *message = [self.chatMessages objectAtIndex:(indexPath.row + hiddenMessages)];
        NSDictionary *msgId = [message objectForKey:@"id"];
        NSDictionary *participant = [msgId objectForKey:@"participant"];
        NSString *author = [participant objectForKey:@"user"];
        
        if (author == nil || [author length] == 0) {
            // Fallback incase author is missing
            return [UIImage imageNamed:@"PersonalChatOS6Large.png"];
        }
        
        UIImage *cachedImage = [appDelegate.profileImages objectForKey:author];
        if (cachedImage) {
            return cachedImage;
        }
        
        NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-largeprofile", author]];
        UIImage *image = imageData ? [UIImage imageWithData:imageData] : [UIImage imageNamed:@"PersonalChatOS6Large.png"];
        
        if (image) {
            [appDelegate.profileImages setObject:image forKey:author];
        }
        
        return image;
    } else {
        if(![appDelegate.profileImages objectForKey:self.contactNumber]){
            NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-largeprofile", self.contactNumber]];
            if(!imageData){
                return [UIImage imageNamed:@"PersonalChatOS6Large.png"];
            } else {
                [appDelegate.profileImages setObject:[UIImage imageWithData:imageData] forKey:self.contactNumber];
                return [appDelegate.profileImages objectForKey:self.contactNumber];
            }
        } else {
            return [appDelegate.profileImages objectForKey:self.contactNumber];
        }
    }
}

- (UIImage *)avatarImageForOutgoingMessage
{
    if(![appDelegate.profileImages objectForKey:[appDelegate.contactsViewController.myContact objectForKey:@"number"]]){
        NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-largeprofile", [appDelegate.contactsViewController.myContact objectForKey:@"number"]]];
        if(!imageData){
            return [UIImage imageNamed:@"PersonalChatOS6Large.png"];
        } else {
            [appDelegate.profileImages setObject:[UIImage imageWithData:imageData] forKey:[appDelegate.contactsViewController.myContact objectForKey:@"number"]];
            return [appDelegate.profileImages objectForKey:[appDelegate.contactsViewController.myContact objectForKey:@"number"]];
        }
    } else {
        return [appDelegate.profileImages objectForKey:[appDelegate.contactsViewController.myContact objectForKey:@"number"]];
    }
}

@end
