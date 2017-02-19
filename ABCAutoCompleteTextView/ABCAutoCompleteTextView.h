//
//  ABCAutoCompleteTextView.h
//  ABCAutoCompleteTextView
//
//  Created by Adam Cooper on 10/16/15.
//  Copyright © 2015 Adam Cooper. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABCAutoCompleteTextView : UITextView

//Data Arrays
@property (nonatomic, strong) NSArray *usernamesArray;
@property (nonatomic, strong) NSArray *hashtagsArray;
@property (nonatomic, strong) UITableView *tableView; // made public to reach it outside

@property (nonatomic, retain) IBInspectable NSString *placeholder;  // Placeholder
@property (nonatomic, retain) IBInspectable UIColor *placeholderColor;


@end
