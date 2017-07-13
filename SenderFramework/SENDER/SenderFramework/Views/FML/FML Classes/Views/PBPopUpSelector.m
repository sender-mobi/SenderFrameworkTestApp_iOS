//
//  PBPopUpSelector.m
//
//  Created by Eugene Gilko on 7/24/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//


#import "PBPopUpSelector.h"
#import "PBConsoleConstants.h"

@interface PBPopUpSelector()
{
    UIButton * cancelButton;
    UITableView * mainTable;
}

@end

@implementation PBPopUpSelector

- (id)initWithFrame:(CGRect)frame andModel:(MainConteinerModel *)model
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.viewModel = model;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    }
    return self;
}

- (void)addCancelButton
{
    CGFloat cancelButtonWidth = 100.0f;
    CGFloat cancelButtonHeight = 55.0f;
    
    CGRect cancelFrame = CGRectMake((self.frame.size.width - cancelButtonWidth)/2,
                                    self.frame.size.height - cancelButtonHeight - 15.0f,
                                    cancelButtonWidth,
                                    cancelButtonHeight);
    cancelButton = [[UIButton alloc] initWithFrame:cancelFrame];
    
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithRed:100/255.0 green:180/255.0 blue:240/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:22.0]];
    
    [cancelButton addTarget:self action:@selector(cancellPushed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:cancelButton];
}

- (void)setupTableView
{
    mainTable = [[UITableView alloc] init];
    mainTable.scrollEnabled = NO;
    mainTable.dataSource = self;
    mainTable.delegate = self;
    
    int count = (int)self.viewModel.vars.count;
    
    int w = self.frame.size.width - 60.0;
    
    CGRect rect = CGRectMake(30.0, 100.0, w, count * 70.0);
    
    if (count > 5) {
        
        rect.size.height = 350;
        mainTable.scrollEnabled = YES;
    }
    
    mainTable.frame = rect;
    mainTable.backgroundColor = [UIColor clearColor];
//    [mainTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [mainTable setContentInset:UIEdgeInsetsZero];
    [self addSubview:mainTable];
    
    [self addCancelButton];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.viewModel.vars.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ChatCellIdentifier = @"ChatCellIdentifier";

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ChatCellIdentifier];

    cell.textLabel.text = [[[self.viewModel.vars objectAtIndex:indexPath.row] valueForKey:@"t"] description];
    cell.textLabel.font = [PBConsoleConstants headerFont];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.minimumScaleFactor = 0.5;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    UIView * bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [PBConsoleConstants colorGrey];
    [cell setSelectedBackgroundView:bgColorView];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [self.delegate didSelectRow:self row:(int)indexPath.row];
}

- (void)dataSelected:(int)row
{
    [self.delegate didSelectRow:self row:1];
}

- (IBAction)cancellPushed:(id)sender
{
    [self.delegate selectCanceled:self];
}

@end
