//
//  DetailViewController.h
//  AL_Notes
//
//  Created by Michael Adkins on 6/18/14.
//  Copyright (c) 2014 Archanet Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface DetailViewController : UIViewController<UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *noteData;
@property (strong, nonatomic) id detailItem;
- (IBAction)actionBtn:(id)sender;
-(void)mailCurrentNote;
-(void)trashNote;
@end
