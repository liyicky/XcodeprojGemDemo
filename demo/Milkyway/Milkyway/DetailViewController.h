//
//  DetailViewController.h
//  Milkyway
//
//  Created by Jason Cheladyn on 11/11/13.
//  Copyright (c) 2013 Jason Cheladyn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
