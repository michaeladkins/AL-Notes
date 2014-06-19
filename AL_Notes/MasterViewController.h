//
//  MasterViewController.h
//  AL_Notes
//
//  Created by Michael Adkins on 6/18/14.
//  Copyright (c) 2014 Archanet Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MasterViewController : UITableViewController <UIAlertViewDelegate>{
    
}
- (void)checkNetworkStatus:(NSNotification *)networkNotice;
- (void)updateNote:(NSNotification*)noteData;
- (void)deleteNote:(NSNotification *)noteData;
- (void)refreshData:(BOOL)wasPulledDown;
- (void)insertNewObject:(id)sender;


@end
