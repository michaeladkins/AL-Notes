//
//  DetailViewController.h
//  AL_Notes
//
//  Created by Michael Adkins on 6/18/14.
//  Copyright (c) 2014 Archanet Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
