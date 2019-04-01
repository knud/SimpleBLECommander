/*!
 * @file CommandResultController.m
 * @author Steven Knudsen
 * @date 2018-04-01
 * @brief The BLE command controller command result controller.
 *
 * This file is part of the Simple BLE Commander example.
 *
 * Copyright (C) 2019 by Steven Knudsen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#import "CommandResultController.h"

@interface CommandResultController ()

@end

@implementation CommandResultController

@synthesize commandName;
@synthesize commandResult;

- (void)viewDidLoad {
  [super viewDidLoad];
  }

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *cellIdentifier = @"resultCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier];
  }
  [cell.textLabel setText:self->commandName];
  [cell.detailTextLabel setText:self->commandResult];
  
  return cell;
}

@end
