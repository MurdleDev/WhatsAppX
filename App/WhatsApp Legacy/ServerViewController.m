//
//  ServerViewController.m
//  WhatsApp Legacy
//
//  Created by CalvinK19 on 6/15/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "ServerViewController.h"
#import "AppDelegate.h"
#import "JSONUtility.h"
#import "AppDelegate.h"

@interface ServerViewController () <UITextFieldDelegate>
@end


@implementation ServerViewController

@synthesize serverA;
@synthesize serverB;
@synthesize serverAport;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Server";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.serverA.delegate = self;
    self.serverB.delegate = self;
    self.serverAport.delegate = self;
    
    self.serverA.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-a-address"];
    self.serverB.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"];
    self.serverAport.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-a-port"];
    
    self.deleteCacheButton.layer.cornerRadius = 4;
    self.deleteCacheButton.layer.masksToBounds = YES;
    
    self.resetSettingsButton.layer.cornerRadius = 4;
    self.resetSettingsButton.layer.masksToBounds = YES;

    // Create Apply button
    UIBarButtonItem *applyButton = [[[UIBarButtonItem alloc]
                                     initWithTitle:@"Apply"
                                     style:UIBarButtonItemStyleDone
                                     target:self
                                     action:@selector(doneSetup:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = applyButton;
}

- (IBAction)doneSetup:(id)sender {
    if((self.serverA.text.length == 0) || (self.serverB.text.length == 0)){
        UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:@"A field is empty." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alerta show];
    } else {
        NSString *urlString = serverA.text;
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"HEAD"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        if (connection) {
            [serverA resignFirstResponder];
            [serverB resignFirstResponder];
            
            // Save inputs BEFORE logging or using them
            [[NSUserDefaults standardUserDefaults] setObject:serverA.text forKey:@"wspl-a-address"];
            [[NSUserDefaults standardUserDefaults] setObject:serverB.text forKey:@"wspl-b-address"];
            [[NSUserDefaults standardUserDefaults] setObject:serverAport.text forKey:@"wspl-a-port"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Applied" message:@"The app will now close." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            alerta.tag = 1001;
            [alerta show];

        } else {
            UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:@"The address entered is invalid." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alerta show];
        }
    }
}

- (IBAction)deleteCacheTapped:(id)sender {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error];
    
    if (error) {
        NSLog(@"Error getting files from documents directory: %@", [error localizedDescription]);
        UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alerta show];
        return;
    }
    
    for (NSString *file in files) {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success || error) {
            NSLog(@"Failed to delete file: %@, error: %@", filePath, [error localizedDescription]);
            UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to delete file: %@, error: %@", filePath, [error localizedDescription]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alerta show];
        }
    }
    
    NSLog(@"All files deleted from Documents directory.");
    UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Success" message:@"All cache was deleted." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alerta show];
}

- (IBAction)resetSettingsTapped:(id)sender {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    [defs removeObjectForKey:@"wspl-a-address"];
    [defs removeObjectForKey:@"wspl-b-address"];
    [defs removeObjectForKey:@"wspl-a-port"];
    [defs removeObjectForKey:@"doneSetup"];
    [defs synchronize];

    self.serverA.text = @"";
    self.serverB.text = @"";
    self.serverAport.text = @"";

    UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:@"Reset Complete" message:@"The app will now close." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alerta.tag = 1001;
    [alerta show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1001) {
        exit(0);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)dealloc {
    [super dealloc];
}
@end
