//
//  MasterViewController.m
//  AL_Notes
//
//  Created by Michael Adkins on 6/18/14.
//  Copyright (c) 2014 Archanet Technologies LLC. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import <Parse/Parse.h>
#import "Reachability.h"

@interface MasterViewController () {
    Reachability *netIsReachable;
    Reachability *hostIsReachable;
    BOOL networkIsActive;
    NSMutableArray *_objects;
    UIRefreshControl *refreshNotes;
    NSInteger *selectedIndex;
}
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;

    // Add the pull down to refresh.
    refreshNotes = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:refreshNotes];
    [refreshNotes addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNote:) name:@"updateNote" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData:) name:@"refreshData" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteNote:) name:@"deleteNote" object:nil];

//    if (networkIsActive == NO){
//        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"We need a network connection to do our job here!" message:@"\n" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//        [alertview show];
//    }else{
        [self refreshData:NO];
//    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:@"kReachabilityChangedNotification" object:nil];

    netIsReachable = [Reachability reachabilityForInternetConnection];
    [netIsReachable startNotifier];
    
    hostIsReachable = [Reachability reachabilityForInternetConnection];
    [hostIsReachable startNotifier];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)checkNetworkStatus:(NSNotification *)networkNotice
{
    NetworkStatus netStatus = [netIsReachable currentReachabilityStatus];
    NetworkStatus hostStatus = [hostIsReachable currentReachabilityStatus];
    
    switch (netStatus) {
        case NotReachable:
            NSLog(@"No Network...");
            networkIsActive = NO;
            break;
        case ReachableViaWiFi:
            networkIsActive = YES;
            break;
        case ReachableViaWWAN:
            networkIsActive = YES;
            break;
    }

    switch (hostStatus) {
        case NotReachable:
            NSLog(@"No Network...");
            networkIsActive = NO;
            break;
        case ReachableViaWiFi:
            networkIsActive = YES;
            break;
        case ReachableViaWWAN:
            networkIsActive = YES;
            break;
    }

}

- (void)updateNote:(NSNotification*)noteData
{
    //noteData:
    //   0 = objectId
    //   1 = NoteData
    
    // Update the local Value.
    for (PFObject *object in _objects) {
        if ([[object objectId] isEqualToString:[[noteData object] objectAtIndex:0]]){
            [object setValue:[[noteData object] objectAtIndex:1] forKey:@"NoteData"];
        }
    }
    
    // Save the note data back to Parse.
    PFQuery *noteQuery = [PFQuery queryWithClassName:@"Notes"];
    
    // Retrieve the object by id
    [noteQuery getObjectInBackgroundWithId:[[noteData object] objectAtIndex:0] block:^(PFObject *noteInfo, NSError *error) {
        if (!error) {
            noteInfo[@"NoteData"] = [[noteData object] objectAtIndex:1];
            [noteInfo saveInBackground];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"Houston - We have a network problem." message:@"\n" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertview show];
        }
    }];
}

- (void)deleteNote:(NSNotification *)noteData
{
    if (networkIsActive == NO){
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"We need a network connection to do our job here!" message:@"\n" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertview show];
    }else{
        // Remove it from Parse
        PFObject *noteInfo = [_objects objectAtIndex:(int)selectedIndex];
        [noteInfo deleteInBackground];
    }
    [_objects removeObjectAtIndex:(int)selectedIndex];
    [self.tableView reloadData];
}

- (void)refreshData:(BOOL)wasPulledDown
{
    __block UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(145, 236, 24, 24);
    [self.view addSubview:spinner];
    [spinner startAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Notes"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {
        if (!error) {
            // Do something with the found objects
            _objects = [[NSMutableArray alloc] initWithArray:objects2 copyItems:NO];
            
            [self.tableView reloadData];
            NSLog(@"%@",_objects);
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"Houston - We have a network problem." message:@"\n" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertview show];
        }
        
        if (!wasPulledDown){
            [refreshNotes endRefreshing];
        }
        
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }

    UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"What would you like to name your note?." message:@"\n" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    
    [alertview setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alertview setTag:1];
    [alertview show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (alertView.tag==1){
        NSString *userNoteName;
        userNoteName = [[alertView textFieldAtIndex:0] text];
        if ([userNoteName length] == 0){
            userNoteName = @"Seriously?!";
        }
        
        // Save the note name to Parse.
        PFObject *noteInfo = [PFObject objectWithClassName:@"Notes"];
        noteInfo[@"NoteName"] = userNoteName;
        noteInfo[@"NoteUpdateDate"] = [NSDate date];
        [noteInfo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if(succeeded){
                 [self refreshData:NO];
             }else{
                 UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"An error occurred while saving your data.  Try again." message:@"\n" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                 [alertview show];
             }
             
         }];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSArray *object = _objects[indexPath.row];
    cell.textLabel.text = [object valueForKey:@"NoteName"];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        selectedIndex = (NSInteger *)indexPath.row;
        NSLog(@"selected index = %d",(int)selectedIndex);

        [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteNote" object:nil];

//        // Remove it from Parse
//        PFObject *noteInfo = [_objects objectAtIndex:indexPath.row];
//        [noteInfo deleteInBackground];
//
//        [_objects removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSMutableArray *object = _objects[indexPath.row];
        selectedIndex = (NSInteger *)indexPath.row;
        
        NSLog(@"my obj = %@,  selectedIndex = %d",object, (int)selectedIndex);
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:[object valueForKey:@"NoteName"] style:UIBarButtonItemStylePlain target:nil action:nil];
        [[segue destinationViewController] setDetailItem:object];
    }
}

@end
