//
// Created by Roman Serga on 1/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatPickerViewController.h"
#import "EntityViewModel.h"
#import "UIView+FindSearchTextField.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "ChatPickerViewControllerTableDelegate.h"
#import "ChatPickerSearchTableDataSource.h"

@interface ChatPickerViewController()

@property (nonatomic, strong) ChatSearchManager * searchManager;
@property (nonatomic, strong) SuperChatListViewController * searchDisplayViewController;

@end

@implementation ChatPickerViewController

#pragma mark - Initialization

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = SenderFrameworkLocalizedString(@"select_user_ios", nil);
        self.pickerTableDataSource = [[ChatPickerSearchTableDataSource alloc] init];
        self.pickerTableDelegate = [[ChatPickerViewControllerTableDelegate alloc] initWithDataSource:self.pickerTableDataSource];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.title = SenderFrameworkLocalizedString(@"select_user_ios", nil);
        self.pickerTableDataSource = [[ChatPickerSearchTableDataSource alloc] init];
        self.pickerTableDelegate = [[ChatPickerViewControllerTableDelegate alloc] initWithDataSource:self.pickerTableDataSource];
    }
    return self;
}

#pragma mark - Implementation

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.pickerTableDataSource.tableView = self.tableView;

    self.tableView.dataSource = self.pickerTableDataSource;
    self.tableView.delegate = self.pickerTableDelegate;
    self.tableView.allowsMultipleSelection = [self.presenter isMultipleSelectionAllowed];

    self.pickerTableDelegate.presenter = self.presenter;

    [self customizeNavigationBar];
    [self addSearchController];
    [self fixSearchBarColors];

    [self.presenter viewWasLoaded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self customizeNavigationBar];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self fixSearchTableInset];
}

- (void)fixSearchTableInset
{
    CGRect searchBarFrameInSearchTable = [self.tableView convertRect:self.searchManager.searchController.searchBar.frame
                                                              toView:self.searchDisplayViewController.tableView];
    CGFloat newTopInset = CGRectGetMaxY(searchBarFrameInSearchTable);
    UIEdgeInsets inset = UIEdgeInsetsMake(newTopInset, 0.0, 0.0, 0.0);
    self.searchDisplayViewController.tableView.scrollIndicatorInsets = inset;
    self.searchDisplayViewController.tableView.contentInset = inset;
}

- (void)customizeNavigationBar
{
    UINavigationBar * navigationBar = self.navigationController.navigationBar;
    [[SenderCore sharedCore].stylePalette customizeNavigationBar:navigationBar];

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = NO;

    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(closeButtonPressed:)];
    cancelButton.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    self.navigationItem.leftBarButtonItem = cancelButton;
    if ([self.presenter isMultipleSelectionAllowed])
    {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonPressed:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        doneButton.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    }

    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
    [[self navigationController]setNavigationBarHidden:NO];
}

- (void)fixSearchBarColors
{
    NSDictionary * textAttributes = @{NSForegroundColorAttributeName:[SenderCore sharedCore].stylePalette.mainTextColor,
            NSFontAttributeName : [SenderCore sharedCore].stylePalette.inputTextFieldFont};
    UITextField * searchTextField = [self.searchManager.searchController.searchBar searchTextField];
    [searchTextField setDefaultTextAttributes: textAttributes];
    [searchTextField setBackgroundColor:[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor];
}

- (void)addSearchController
{
    NSString * sbName = @"SuperChatListViewController";
    self.searchDisplayViewController = [SuperChatListViewController loadFromSenderFrameworkStoryboardWithName: sbName];
    //Loading view in order to have non-nil tableView
    self.searchDisplayViewController.view;
    self.searchDisplayViewController.tableView.allowsMultipleSelection = [self.presenter isMultipleSelectionAllowed];

    self.searchTableDataSource = [[ChatPickerSearchTableDataSource alloc] init];
    self.searchTableDataSource.tableView = self.searchDisplayViewController.tableView;

    self.searchManager = [[ChatSearchManager alloc] initWithSearchDisplayController:self.searchDisplayViewController
                                                                searchManagerOutput:self.searchTableDataSource
                                                                 searchManagerInput:self.pickerTableDelegate];

    self.searchDisplayViewController.tableView.delegate = self.pickerTableDelegate;
    self.searchManager.searchController.delegate = self;
    self.searchManager.searchController.hidesNavigationBarDuringPresentation = NO;

    UISearchBar *searchBar = self.searchManager.searchController.searchBar;
    searchBar.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    searchBar.showsCancelButton = NO;
    self.tableView.tableHeaderView = searchBar;

    self.definesPresentationContext = YES;
    self.searchDisplayViewController.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)closeButtonPressed:(id)sender
{
    [self.presenter cancelPickingEntities];
}

- (void)doneButtonPressed:(id)sender
{
    [self.presenter startFinishingPickingEntities];
}

#pragma mark - UISearchController Delegate

- (void)willPresentSearchController:(UISearchController *)searchController
{
    self.pickerTableDelegate.dataSource = self.searchTableDataSource;
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    self.pickerTableDelegate.dataSource = self.pickerTableDataSource;

    for (NSIndexPath * indexPath in [self.tableView indexPathsForSelectedRows])
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView reloadData];
}

#pragma mark - ChatPickerDisplayController

- (void)showNoUsersSelectedError
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"select_person_ios", nil)
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];
    [alert addAction:okAction];
    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

#pragma mark - EntityPicker View

- (void)entityWasUpdated:(id<EntityViewModel>)entity
{
    NSIndexPath * entityIndexPath = [self.pickerTableDataSource indexPathForChatModel:entity];
    if (entityIndexPath)
        [self.tableView reloadRowsAtIndexPaths:@[entityIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateWithEntities:(NSArray *)entities
{
    self.pickerTableDataSource.chatModels = entities;
    [self.tableView reloadData];
    self.searchManager.localModels = entities;
}

@end