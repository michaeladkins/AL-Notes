//
//  DetailViewController.m
//  AL_Notes
//
//  Created by Michael Adkins on 6/18/14.
//  Copyright (c) 2014 Archanet Technologies LLC. All rights reserved.
//

#import "DetailViewController.h"
#import <Parse/Parse.h>

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.detailItem) {
        __block UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.frame = CGRectMake(145, 236, 24, 24);
        [self.view addSubview:spinner];
        [spinner startAnimating];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

        // Lets just grab the NoteData sitting on Parse.  This way if there are changes, we have them.
        PFQuery *noteQuery = [PFQuery queryWithClassName:@"Notes"];
        
        // Retrieve the object by id
        [noteQuery getObjectInBackgroundWithId:[self.detailItem objectId] block:^(PFObject *noteInfo, NSError *error) {
            if (!error) {
                self.noteData.text = [noteInfo valueForKey:@"NoteData"];
                [spinner stopAnimating];
                [spinner removeFromSuperview];
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            } else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
                UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"Houston - We have a network problem." message:@"\n" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertview show];
                [spinner stopAnimating];
                [spinner removeFromSuperview];
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            }
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSArray *retData = [[NSArray alloc] initWithObjects:[self.detailItem valueForKey:@"objectId"], self.noteData.text, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateNote" object:retData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionBtn:(id)sender
{

    // Give the users some options of what to do with this info...
    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:@"What would you like to do with this note?"
                            delegate:self
                            cancelButtonTitle:@"Cancel"
                            destructiveButtonTitle:nil
                            otherButtonTitles:@"Email It!", @"Trash It?", @"Hide Keyboard!", nil];
    [sheet setTag:0];
    [sheet showInView:self.view];
}


-(void)actionSheet:(UIActionSheet *)actionSheet1 clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet1.tag == 0){
        if (buttonIndex == 0) {
            NSLog(@"Email It Button Clicked");
            [self mailCurrentNote];
        } else if (buttonIndex == 1) {
            NSLog(@"Trash It Button Clicked");
            [self trashNote];
        } else if (buttonIndex == 2) {
            NSLog(@"Done Editting");
            [self.noteData resignFirstResponder];
        } else if (buttonIndex == 3) {
            NSLog(@"Cancel Button Clicked");
        }
    }
}

// Mail Stuff
-(void)mailCurrentNote
{
    if ([MFMailComposeViewController canSendMail]){
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:[self.detailItem valueForKey:@"NoteName"]];
        
        NSString *emailBody = self.noteData.text;
        [picker setMessageBody:emailBody isHTML:NO];
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


// Trash the Note and return
-(void)trashNote
{
    PFObject *noteInfo = [self detailItem];
    [noteInfo deleteInBackground];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteNote" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
