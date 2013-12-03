//
//  TCDetailViewController.h
//  GenCov
//
//  Created by Jason Cheladyn on 12/3/13.
//  Copyright (c) 2013 Jason Cheladyn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
